# 🚀 GitHub Pages Deployment — Ghi chú triển khai

## 🔗 Link game online

**https://leuyennhi67.github.io/Cocaro/**

> Sau lần đầu build hoàn tất (khoảng 3–5 phút), link này sẽ hoạt động.
> Mỗi lần `git push` lên branch `master` sẽ tự động deploy lại.

---

## 📁 File đã tạo

| File | Mục đích |
|------|----------|
| `.github/workflows/deploy.yml` | GitHub Actions workflow: tự động build Flutter Web và deploy lên GitHub Pages mỗi khi push lên `master` |

---

## ⚙️ Workflow hoạt động như thế nào

```
git push master
    ↓
GitHub Actions trigger
    ↓
[Job: build]
  - Checkout code
  - Cài Flutter 3.32.0 stable
  - flutter pub get
  - flutter build web --release --base-href "/Cocaro/" --web-renderer canvaskit
  - Upload artifact (thư mục build/web)
    ↓
[Job: deploy]
  - Deploy artifact lên GitHub Pages
    ↓
https://leuyennhi67.github.io/Cocaro/ ✅
```

---

## 🛠️ Lệnh GitHub CLI đã dùng

```bash
# Kiểm tra đăng nhập
gh auth status

# Lấy thông tin repo
gh repo view --json name,defaultBranchRef,isPrivate,url,id

# Đổi repo từ private sang public (cần thiết cho GitHub Pages free plan)
gh repo edit LeUyenNhi67/Cocaro --visibility public --accept-visibility-change-consequences

# Kích hoạt GitHub Pages, dùng GitHub Actions làm nguồn deploy
gh api repos/LeUyenNhi67/Cocaro/pages --method POST \
  -H "Accept: application/vnd.github+json" \
  -f "build_type=workflow"

# Kiểm tra trạng thái workflow
gh run list --workflow=deploy.yml --limit 5
```

---

## 👀 Theo dõi tiến trình build

```bash
# Xem danh sách run gần nhất
gh run list --workflow=deploy.yml --limit 5

# Xem log realtime của lần build mới nhất
gh run watch
```

Hoặc vào thẳng: **https://github.com/LeUyenNhi67/Cocaro/actions**

---

## ✅ Việc đã tự động hoàn toàn

- [x] Tạo file `.github/workflows/deploy.yml`
- [x] Đổi repo sang **Public**
- [x] Kích hoạt **GitHub Pages** (source: GitHub Actions)
- [x] Push workflow lên GitHub → CI đã chạy ngay lập tức

## ⚠️ Lưu ý

- **Repo hiện là Public**: Code Dart của bạn ai cũng có thể xem.
  Supabase keys (`publishableKey`) trong code là **public key** (an toàn để public), nhưng hãy đảm bảo không commit service role key hoặc secret nào khác.
- Lần deploy đầu tiên mất **3–5 phút**. Các lần sau nhanh hơn nhờ cache Flutter.
- Nếu muốn đổi lại về Private sau này, cần nâng GitHub Pro hoặc chuyển sang Cloudflare Pages.
