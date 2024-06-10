Kimia Farama dataset
•  Diberikan beberapa data tabel yaitu: penjualan,barang dan pelanggan.
•  Setelah data di import tabel tabel tersebut dilakukan proses pengecekan terlebih dahulu
   seperti pengecekan null, pergantian type kolom, pengaturan kolom, indexing, serta 
   penentuan primary key dan foreign key
•  Kemudian dibuatlah base data mart dari ketiga tabel tersebut menggunakan JOIN, dimana:
   id customer penjualan = id customer pelanggan dan id_barang penjualan = kode barang barang
•  Dilanjutkan membuat data mart dengan penambah kolom agregasi menggunakan _COMmon Table Expression_,
    Dimana pada kolom agregasi menampilkan nilai nilai sebagai berikut:
    1. Total pendapatan bulanan
    2. Insight penggan (jumlah transaksi pelanggan, total harga baranga yang dibeli, dan rata rata jumlah barang yang dibeli
    3. Insight Produk (Junka terjual perbarang, total pendapatan perbarangm dan rata rata yang terjual)
    4. Total keseluruhan (total transaksi, total pendapatan, dan rata rata pendapatan)

