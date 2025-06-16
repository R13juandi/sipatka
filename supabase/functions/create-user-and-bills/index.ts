import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.44.2";

// Header CORS untuk memperbolehkan request dari mana saja
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

console.log("Create-user-and-bills function initialized");

serve(async (req) => {
  // Handle preflight request (permintaan OPTIONS dari browser/aplikasi)
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Ambil data yang dikirim dari aplikasi Flutter
    const { email, password, spp_amount, academic_year_start, user_data } = await req.json();

    // Validasi input sederhana
    if (!email || !password || !spp_amount || !academic_year_start || !user_data) {
      throw new Error("Data yang dikirim tidak lengkap.");
    }

    // 2. Buat "Admin Client" untuk Supabase agar bisa menjalankan perintah khusus admin
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // 3. Buat user baru di sistem Otentikasi Supabase
    // user_data akan disimpan sebagai metadata yang akan dibaca oleh trigger database
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: email,
      password: password,
      email_confirm: true, // User tidak perlu verifikasi email
      user_metadata: user_data, 
    });

    if (authError) {
      throw authError;
    }
    
    console.log(`User created successfully: ${authData.user.email}`);

    // Catatan: Trigger database 'handle_new_user' yang sudah kita buat di SQL
    // akan otomatis mengisi tabel 'profiles' dan 'students' setelah user ini dibuat.

    // 4. Buat 12 tagihan pembayaran untuk siswa baru tersebut
    const newUserId = authData.user.id;
    const newStudentId = (await supabaseAdmin.from('students').select('id').eq('parent_id', newUserId).single()).data?.id;

    if (!newStudentId) {
        throw new Error("Gagal menemukan data siswa yang baru dibuat.");
    }

    const paymentsToInsert = [];
    const months = ["Juli", "Agustus", "September", "Oktober", "November", "Desember", "Januari", "Februari", "Maret", "April", "Mei", "Juni"];
    
    for (let i = 0; i < 12; i++) {
      const year = i < 6 ? academic_year_start : academic_year_start + 1;
      const monthName = months[i];
      // Jatuh tempo diatur tanggal 10 setiap bulan
      const dueDate = new Date(year, i + 6, 10);

      paymentsToInsert.push({
        student_id: newStudentId,
        month: monthName,
        year: year,
        amount: spp_amount,
        due_date: dueDate.toISOString().split('T')[0], // Format YYYY-MM-DD
      });
    }

    // Masukkan 12 tagihan sekaligus ke tabel 'payments'
    const { error: paymentsError } = await supabaseAdmin.from('payments').insert(paymentsToInsert);

    if (paymentsError) {
      throw paymentsError;
    }

    console.log(`Successfully created 12 payments for student: ${newStudentId}`);

    // 5. Kirim kembali pesan sukses ke aplikasi Flutter
    return new Response(JSON.stringify({ success: true, message: "User dan 12 tagihan berhasil dibuat!" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ success: false, error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});