DAO VU KARATE ONLINE - BAN DA SUA KET NOI SUPABASE

THANH PHAN
- index.html: ung dung web, giu giao dien va chuc nang quan ly trong file goc.
- supabase_setup.sql: tao cac bang, phan quyen co ban va bang app_state dung voi ung dung.

TRIEN KHAI VERCEL
1. Tai ve va giai nen thu muc dao-vu-karate-online.
2. Dua index.html va supabase_app_state_setup.sql vao thu muc goc repository GitHub dao-vu-karate-online.
3. Commit va push len GitHub. Vercel se tu dong build lai static site; khong can npm install.
4. Trong Supabase SQL Editor, chay toan bo file supabase_setup.sql.
5. Trong Supabase Authentication > Users, tao tai khoan email/mat khau quan ly.
6. Trong SQL Editor, cap quyen admin cho email vua tao bang lenh (thay email that):
   update public.profiles
   set role = 'admin'
   where id = (select id from auth.users where email = 'EMAIL_QUAN_LY_CUA_BAN');
7. Mo website > Cai dat vo duong > Dong bo dam may Supabase.
8. Nhap Project URL: https://cwmnvmhywfkmmqebmbhl.supabase.co
9. Nhap Publishable key cua CHINH project nay (lay trong Supabase Project Settings > API Keys).
10. Nhap email/mat khau Supabase Auth vua tao, bam Dang nhap & tai du lieu.
11. Sau khi dang nhap thanh cong, bam Dong bo ngay. Khi chinh sua va luu du lieu, ung dung se tu dong dong bo.

LUU Y QUAN TRONG
- Khong dua Secret key/service_role key vao HTML, GitHub, Vercel Environment Variables hay trinh duyet.
- HTML nay su dung Publishable key va Supabase Auth; khong can khai bao Vercel Environment Variables cho cach cau hinh hien tai.
- Ban goc su dung localStorage lam bo nho du phong; ban sua tranh viec tu dong day du lieu local cu len may chu ngay khi vua mo trang.
- Co che hien tai dong bo mot goi du lieu JSON cho tai khoan quan tri. Cong phu huynh van dang tra cuu bang ma vo sinh + so dien thoai trong du lieu da tai; chua phai he thong tai khoan rieng cho tung phu huynh.
- Neu project Supabase chua co bang profiles, can chay schema goc truoc khi chay file SQL bo sung nay.
