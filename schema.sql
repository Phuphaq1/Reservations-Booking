-- =====================================================================
-- ในสวน เขาใหญ่ — Supabase schema
-- วิธีใช้: Supabase Dashboard → SQL Editor → New query → วางไฟล์นี้ทั้งหมด → Run
-- =====================================================================

-- ============ 1) PROPERTY SETTINGS (แถวเดียว เก็บค่าตั้งค่าทั้งหมด) ============
create table property_settings (
  id integer primary key default 1,
  name text not null default 'ในสวน เขาใหญ่',
  sub text default 'NAI SUAN KHAOYAI',
  phone text default '092-988-9808',
  line_url text default '',
  facebook_url text default '',
  instagram_url text default '',
  hero_headline text default 'จองที่พักได้ในไม่กี่คลิก',
  hero_lede text default 'เลือกวันที่ ยืนยันยอด แล้วค่อยชำระ',
  hero_img text default '',
  line_qr_img text default '',
  policy_text text default '',
  booking_open boolean not null default true,
  max_advance_days integer not null default 90,
  min_notice_days integer not null default 0,
  deposit_percent integer not null default 30,
  constraint single_row check (id = 1)
);
insert into property_settings (id) values (1);

-- ============ 2) ROOMS ============
create table rooms (
  id text primary key,
  type_id text not null,
  type_name text not null,
  type_color text not null,
  name text not null,
  description text,
  capacity integer not null default 2,
  price integer not null default 0,
  units integer not null default 1,
  img text,
  sort_order integer default 0
);

-- ตัวอย่างข้อมูลเริ่มต้น (ลบ/แก้ไขได้ตามจริง หรือแก้จากหน้าเว็บฝั่งเจ้าของที่พักภายหลัง)
insert into rooms (id, type_id, type_name, type_color, name, description, capacity, price, units) values
('r1','forest','กระท่อมป่าเล็ก','#F59E0B','กระท่อมป่าเล็ก','ห้องนอน+นั่งเล่นแยกโซน แอร์ทั้งสองห้อง เหมาะกับคู่รักหรือมาคนเดียว',2,1490,3),
('r2','palm','กระท่อมสวนอินทผลัม','#0EA989','กระท่อมสวนอินทผลัม','ติดสวนอินทผลัม เดินชมวิวได้รอบบ้าน บรรยากาศร่มรื่นตลอดวัน',2,1890,2),
('r3','view','กระท่อมหอชมวิว','#4F46E5','กระท่อมหอชมวิว','ใกล้หอชมวิวที่สุด รับลมเย็นยามเช้าและวิวพระอาทิตย์ตกเต็มตา',3,2290,2),
('r4','family','กระท่อมครอบครัว','#EC4899','กระท่อมครอบครัว','สองห้องนอน รองรับกลุ่มเพื่อนหรือครอบครัว มีครัวเล็กในตัว',5,3200,2);

-- ============ 3) GALLERY PHOTOS ============
create table gallery_photos (
  id bigint generated always as identity primary key,
  src text default '',
  caption text default '',
  sort_order integer default 0
);
insert into gallery_photos (src, caption, sort_order) values
('','ทางเดินเข้าที่พัก',1),('','สวนอินทผลัม',2),('','หอชมวิว',3),
('','ในกระท่อม',4),('','นั่งเล่นกลางแจ้ง',5),('','ยามเช้า',6);

-- ============ 4) BLACKOUT DATES (ปิดรับจองเฉพาะวัน) ============
create table blackout_dates (
  date date primary key
);

-- ============ 5) BOOKINGS ============
create table bookings (
  id bigint generated always as identity primary key,
  code text not null,
  room_id text references rooms(id) on delete set null,
  checkin date not null,
  checkout date not null,
  nights integer not null,
  price_per_night integer not null,
  total integer not null,
  payment_type text not null check (payment_type in ('full','deposit')),
  deposit_amount integer not null default 0,
  balance_due integer not null default 0,
  guest_name text not null,
  guest_phone text not null,
  guest_note text,
  slip_url text,
  status text not null default 'awaiting_verification' check (status in ('awaiting_verification','confirmed','rejected')),
  created_at timestamptz not null default now()
);

-- ============ 6) NOTIFICATIONS ============
create table notifications (
  id bigint generated always as identity primary key,
  role text not null check (role in ('guest','host')),
  title text not null,
  message text not null,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

-- =====================================================================
-- ROW LEVEL SECURITY
-- แนวคิด: ใครก็ตาม (anon) อ่านข้อมูลที่จำเป็นสำหรับหน้าเว็บได้ และ "จอง" ได้
--         ส่วนการแก้ไขราคา/ตั้งค่า/ยืนยันสลิป ต้องล็อกอิน (authenticated) เท่านั้น
-- =====================================================================
alter table property_settings enable row level security;
alter table rooms enable row level security;
alter table gallery_photos enable row level security;
alter table blackout_dates enable row level security;
alter table bookings enable row level security;
alter table notifications enable row level security;

-- อ่านได้แบบสาธารณะ (guest-facing)
create policy "public read property" on property_settings for select using (true);
create policy "public read rooms" on rooms for select using (true);
create policy "public read gallery" on gallery_photos for select using (true);
create policy "public read blackout" on blackout_dates for select using (true);
create policy "public read bookings" on bookings for select using (true); -- ใช้แสดงห้องว่างจริง + แดชบอร์ดฝั่งเจ้าของ
create policy "public read notifications" on notifications for select using (true);

-- ผู้จอง (anon) เพิ่มการจอง/แจ้งเตือนได้ (แต่แก้ไข/ลบไม่ได้)
create policy "public insert bookings" on bookings for insert with check (true);
create policy "public insert notifications" on notifications for insert with check (true);

-- เฉพาะผู้ที่ล็อกอินแล้ว (เจ้าของที่พัก) แก้ไขข้อมูลได้
create policy "auth update property" on property_settings for update using (auth.role() = 'authenticated');
create policy "auth update rooms" on rooms for update using (auth.role() = 'authenticated');
create policy "auth insert gallery" on gallery_photos for insert with check (auth.role() = 'authenticated');
create policy "auth update gallery" on gallery_photos for update using (auth.role() = 'authenticated');
create policy "auth delete gallery" on gallery_photos for delete using (auth.role() = 'authenticated');
create policy "auth insert blackout" on blackout_dates for insert with check (auth.role() = 'authenticated');
create policy "auth delete blackout" on blackout_dates for delete using (auth.role() = 'authenticated');
create policy "auth update bookings" on bookings for update using (auth.role() = 'authenticated');
create policy "auth update notifications" on notifications for update using (auth.role() = 'authenticated');

-- =====================================================================
-- STORAGE BUCKETS
-- ต้องสร้าง bucket ผ่านหน้า Dashboard → Storage ก่อน (SQL สร้าง bucket ไม่ได้โดยตรงในบาง plan)
--   1) สร้าง bucket ชื่อ "photos"  ตั้งเป็น Public
--   2) สร้าง bucket ชื่อ "slips"   ตั้งเป็น Public (เพื่อความง่าย — ถ้าต้องการความเป็นส่วนตัวมากขึ้น
--      ให้ตั้งเป็น Private แล้วใช้ signed URL แทน ซึ่งต้องแก้โค้ดเพิ่มเติม)
-- แล้วรันคำสั่งด้านล่างเพื่อกำหนดสิทธิ์อัปโหลด/อ่านไฟล์
-- =====================================================================
create policy "public read storage objects" on storage.objects for select using (true);
create policy "public upload slips" on storage.objects for insert with check (bucket_id = 'slips');
create policy "auth upload photos" on storage.objects for insert with check (bucket_id = 'photos' and auth.role() = 'authenticated');

-- =====================================================================
-- ผู้ใช้เจ้าของที่พัก (Supabase Auth)
-- สร้างผ่าน Dashboard → Authentication → Users → Add user (ใส่อีเมล/รหัสผ่านเอง)
-- ไม่ต้องรัน SQL เพิ่ม — ใช้อีเมล/รหัสผ่านที่ตั้งไว้ล็อกอินในหน้าเว็บได้เลย
-- =====================================================================
