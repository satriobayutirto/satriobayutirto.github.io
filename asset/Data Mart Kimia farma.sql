-- Editor menggunakan vscode
CREATE DATABASE kimiafarma;
use kimiafarma;
--import data dg import table wizard mysql
--Cleaning penjualan
update penjualan set tanggal= DATE_FORMAT(
        STR_TO_DATE(tanggal, '%m/%d/%Y'),
        '%Y-%m-%d');
ALTER TABLE penjualan
    MODIFY id_invoice VARCHAR(50) NOT NULL PRIMARY KEY UNIQUE COMMENT 'Primary Key',
    MODIFY id_distributor VARCHAR(50) after id_invoice,
    MODIFY id_cabang VARCHAR(50) after id_distributor,
    MODIFY tanggal DATE,
    MODIFY id_customer VARCHAR(15),
    MODIFY id_barang VARCHAR(15),
    MODIFY jumlah_barang INT,
    MODIFY unit VARCHAR(10),
    MODIFY harga INT,
    MODIFY mata_uang VARCHAR (5);
--Drop column MyUnknownColumn manual langsung

--Cleaning pelanggan
SELECT COUNT(id_customer) FROM pelanggan WHERE id_customer='';
SELECT * FROM pelanggan WHERE id_customer='' limit 10;
DELETE FROM pelanggan WHERE id_customer = '';
ALTER TABLE pelanggan
    MODIFY id_customer VARCHAR(50) NOT NULL PRIMARY KEY UNIQUE COMMENT 'Primary Key',
    MODIFY nama VARCHAR(100),
    MODIFY id_cabang_sales VARCHAR(10),
    MODIFY cabang_sales VARCHAR(50),
    MODIFY id_group VARCHAR(5),
    CHANGE `group` `group` VARCHAR(15),
    CHANGE `level` `level` VARCHAR(20);

--cleaning barang
ALTER TABLE barang 
    MODIFY kode_barang VARCHAR(50) NOT NULL PRIMARY KEY UNIQUE COMMENT 'Primary Key',
    MODIFY sektor VARCHAR(5),
    MODIFY nama_barang VARCHAR(100),
    MODIFY tipe VARCHAR(10),
    MODIFY nama_tipe VARCHAR(50),
    MODIFY kode_lini INT,
    MODIFY lini VARCHAR(25),
    MODIFY kemasan VARCHAR(10);

--index dan foreign KEY 
ALTER Table penjualan
    ADD CONSTRAINT fk_id_customer FOREIGN KEY(id_customer) REFERENCES pelanggan(id_customer),
    ADD CONSTRAINT fk_id_barang FOREIGN KEY(id_barang) REFERENCES barang(kode_barang);

CREATE INDEX idx_pelanggan
on pelanggan(cabang_sales,`group`, nama);
CREATE INDEX idx_barang
on barang(nama_barang, lini, kemasan);
CREATE INDEX idx_penjualan
on penjualan(tanggal);
commit;
select DISTINCT id_invoice FROM penjualan;

---------------------------------------------------------------------------------------------------------
--Base TABLE
SELECT
    p.id_invoice,
    pl.nama,
    pl.cabang_sales,
    p.tanggal,
    b.nama_barang,
    b.lini,
    p.jumlah_barang,
    p.unit,
    p.harga, 
    (jumlah_barang*harga) AS total_harga
FROM penjualan p
    JOIN pelanggan pl on p.id_customer = pl.id_customer
    JOIN barang b on p.id_barang = b.kode_barang
    ORDER BY cabang_sales, DATE_FORMAT(tanggal, '%Y-%m'), nama_barang;
    

--Aggregate TABLE
----------------------------------------------------------------------------------------------------------------
WITH base_data AS (
    SELECT
        p.id_invoice,
        pl.nama,
        pl.cabang_sales,
        p.tanggal,
        b.nama_barang,
        b.lini,
        p.jumlah_barang,
        p.unit,
        p.harga,
        (p.jumlah_barang * p.harga) AS total_harga
    FROM penjualan p
    JOIN pelanggan pl ON p.id_customer = pl.id_customer
    JOIN barang b ON p.id_barang = b.kode_barang
),
monthly_revenue AS (
    SELECT
        DATE_FORMAT(tanggal, '%Y-%m') AS periode,
        cabang_sales,
        SUM(jumlah_barang * harga) AS total_pendapatan,
        COALESCE(LEAD(SUM(jumlah_barang * harga)) OVER (PARTITION BY pl.cabang_sales ORDER BY DATE_FORMAT(tanggal, '%Y-%m')), 0) AS total_pendapatan_berikutnya,
        COALESCE(LAG(SUM(jumlah_barang * harga)) OVER (PARTITION BY pl.cabang_sales ORDER BY DATE_FORMAT(tanggal, '%Y-%m')), 0) AS total_pendapatan_sebelumnya
        FROM base_data
    GROUP BY DATE_FORMAT(tanggal, '%Y-%m'), cabang_sales
),
insight_data AS(
    SELECT    
        COUNT(id_invoice) OVER(PARTITION BY nama) AS total_transaksi_pelanggan,
        SUM(jumlah_barang * harga) OVER(PARTITION BY nama) AS total_pembelian_pelanggan,
        AVG(jumlah_barang) OVER(PARTITION BY nama) AS AVG_jumlah_pembelian_pelanggan,    
        SUM(bd.jumlah_barang) OVER(PARTITION BY bd.nama_barang) AS total_produk_terjual,
        SUM(bd.jumlah_barang * bd.harga) OVER(PARTITION BY bd.nama_barang) AS total_pendapatan_produk,
        AVG(bd.jumlah_barang) OVER(PARTITION BY bd.nama_barang) AS AVG_jumlah_pembelian_produk
    FROM base_data bd
),
total_keseluruhan AS (
    SELECT
        count(bd.id_invoice) AS total_transaksi_keseluruhan,
        SUM(bd.jumlah_barang)  AS total_barang_keseluruhan,
        SUM(bd.jumlah_barang*harga) AS total_pendapatan_keseluruhan,
        AVG(bd.jumlah_barang*harga) AS AVG_pendapatan_keseluruhan
    FROM base_data bd
)
SELECT
    bd.id_invoice,
    bd.nama,
    bd.cabang_sales,
    bd.tanggal,
    bd.nama_barang,
    bd.lini,
    bd.jumlah_barang,
    bd.unit,
    bd.harga,
    bd.total_harga,
    id.total_transaksi_pelanggan,
    id.total_pembelian_pelanggan,
    id.AVG_jumlah_pembelian_pelanggan,
    id.total_produk_terjual,
    id.total_pendapatan_produk,
    id.AVG_jumlah_pembelian_produk,
    mr.periode,
    mr.total_pendapatan,
    mr.total_pendapatan_sebelumnya,
    COALESCE(((mr.total_pendapatan - mr.total_pendapatan_sebelumnya) / NULLIF(mr.total_pendapatan_sebelumnya, 0)) * 100, 0) AS growth_rate,
    tk.total_transaksi_keseluruhan,
    tk.total_barang_keseluruhan,
    tk.total_pendapatan_keseluruhan,
    tk.AVG_pendapatan_keseluruhan
FROM base_data bd
JOIN monthly_revenue mr ON bd.cabang_sales = mr.cabang_sales AND DATE_FORMAT(bd.tanggal, '%Y-%m') = mr.periode
,insight_data id, total_keseluruhan tk
ORDER BY bd.cabang_sales, DATE_FORMAT(bd.tanggal, '%Y-%m'), bd.nama_barang;
