const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Cloud Function untuk membuat user, custom role, data di Firestore,
 * dan 12 tagihan SPP untuk satu tahun ajaran.
 * Dipanggil dari aplikasi oleh admin.
 */
exports.adminCreateUserAndBills = functions
  .region("asia-southeast1") // Pastikan region ini sama dengan di kode Flutter Anda
  .https.onCall(async (data, context) => {
    // 1. Verifikasi bahwa pemanggil adalah admin
    if (context.auth.token.role !== "admin") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Gagal! Hanya admin yang dapat menjalankan fungsi ini."
      );
    }

    // 2. Ambil data dari aplikasi
    const { email, password, parentName, studentName, className, academicYearStart, sppAmount } = data;

    // Validasi data sederhana
    if (!email || !password || !parentName || !studentName || !className || !academicYearStart || !sppAmount) {
        throw new functions.https.HttpsError("invalid-argument", "Data yang dikirim tidak lengkap.");
    }

    try {
      // 3. Buat user di Firebase Authentication
      const userRecord = await admin.auth().createUser({ email, password, displayName: parentName });

      // 4. Set Custom Claim agar user ini memiliki role 'user'
      await admin.auth().setCustomUserClaims(userRecord.uid, { role: "user" });

      // 5. Buat dokumen user di koleksi 'users' Firestore
      await db.collection("users").doc(userRecord.uid).set({
        uid: userRecord.uid, email, parentName, studentName, className, role: "user", saldo: 0.0,
      });

      // 6. Buat 12 tagihan SPP untuk satu tahun ajaran
      const batch = db.batch();
      const months = ["Juli", "Agustus", "September", "Oktober", "November", "Desember", "Januari", "Februari", "Maret", "April", "Mei", "Juni"];
      
      for (let i = 0; i < 12; i++) {
        // Tahun ajaran dimulai dari Juli. Juli-Desember menggunakan tahun awal.
        // Januari-Juni menggunakan tahun berikutnya.
        const year = i < 6 ? academicYearStart : academicYearStart + 1;
        const monthName = months[i];
        
        // Jatuh tempo diatur tanggal 10 setiap bulan
        const dueDate = new Date(year, i + 6, 10); // i+6 karena Juli adalah bulan ke-6 (index 0-based)
        
        const paymentRef = db.collection("payments").doc();
        batch.set(paymentRef, {
          userId: userRecord.uid,
          month: `${monthName} ${year}`,
          amount: sppAmount,
          dueDate: admin.firestore.Timestamp.fromDate(dueDate),
          status: "unpaid",
          paidDate: null,
          denda: 0.0,
        });
      }
      
      await batch.commit();

      return { success: true, message: "Sukses! Akun dan 12 tagihan SPP berhasil dibuat." };

    } catch (error) {
      console.error("Error saat membuat user dan tagihan:", error);
      throw new functions.https.HttpsError("internal", error.message);
    }
  });


/**
 * Cloud Function untuk mengkonfirmasi pembayaran.
 * Dipanggil saat admin menekan tombol Konfirmasi.
 */
exports.confirmPaymentAndManageBalance = functions
  .region("asia-southeast1")
  .https.onCall(async (data, context) => {
    if (context.auth.token.role !== "admin") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Gagal! Hanya admin yang dapat menjalankan fungsi ini."
      );
    }
    const { paymentId, actualAmountPaid } = data;
    const paymentRef = db.collection("payments").doc(paymentId);

    try {
        const paymentDoc = await paymentRef.get();
        if (!paymentDoc.exists) {
            throw new functions.https.HttpsError("not-found", "Dokumen pembayaran tidak ditemukan.");
        }

        await paymentRef.update({
            status: "paid",
            isVerified: true, // Opsional, tergantung model data Anda
            paidDate: admin.firestore.FieldValue.serverTimestamp(),
        });

        return { success: true, message: `Pembayaran ${paymentId} berhasil dikonfirmasi.`};
    } catch (error) {
        console.error("Error saat konfirmasi pembayaran:", error);
        throw new functions.https.HttpsError("internal", "Gagal mengkonfirmasi pembayaran.");
    }
});