# My Love

App Flutter ghi nhớ ngày đầu quen nhau, tính thời gian bên nhau và hiển thị các dịp đặc biệt.

## Build IPA chưa ký miễn phí

Windows không có Xcode nên dùng GitHub Actions trên runner macOS:

1. Tạo một repository GitHub public và upload toàn bộ project này.
2. Mở tab **Actions** của repository.
3. Chọn workflow **Build unsigned iOS IPA**.
4. Chọn **Run workflow**.
5. Khi chạy xong, tải artifact `my-love-unsigned-ipa`.

Workflow dùng `flutter build ipa --release --no-codesign`, vì vậy IPA được tạo chưa ký để bạn tự xử lý bước ký sau.
