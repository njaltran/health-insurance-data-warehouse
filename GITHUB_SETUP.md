# GitHub Setup Guide

## 🎯 Your Repository is Ready!

The project has been initialized with Git and best practices applied. Follow these steps to push to GitHub.

---

## ✅ What's Already Done

- ✅ Git repository initialized
- ✅ `.gitignore` created (excludes sensitive files)
- ✅ `.gitattributes` configured (proper line endings)
- ✅ Initial commit created
- ✅ All files staged and committed

---

## 🚀 Push to GitHub

### **Step 1: Create a New Repository on GitHub**

1. Go to: https://github.com/new
2. **Repository name:** `health-insurance-data-warehouse` (or your choice)
3. **Description:** Production-ready dbt project for health data cleaning and transformation
4. **Visibility:**
   - ✅ **Public** (recommended for portfolio)
   - OR Private (if you prefer)
5. **DO NOT** initialize with README, .gitignore, or license (we already have these)
6. Click **"Create repository"**

### **Step 2: Connect Your Local Repository**

GitHub will show you instructions. Run these commands:

```bash
# Add GitHub as remote origin
git remote add origin https://github.com/YOUR_USERNAME/health-insurance-data-warehouse.git

# Verify remote was added
git remote -v

# Push to GitHub
git push -u origin main
```

**Or if you prefer SSH:**

```bash
git remote add origin git@github.com:YOUR_USERNAME/health-insurance-data-warehouse.git
git push -u origin main
```

---

## 📋 Verify Your Push

After pushing, check on GitHub:

1. Go to: `https://github.com/YOUR_USERNAME/health-insurance-data-warehouse`
2. You should see:
   - ✅ README.md displayed on the homepage
   - ✅ 28 files
   - ✅ Commit message visible
   - ✅ Proper folder structure

---

## 🔒 Security Check - Files That Are EXCLUDED

The following sensitive files are **NOT** committed (protected by `.gitignore`):

### **❌ Excluded (Correct - DO NOT commit these):**
- `dbt_health_insurance/profiles.yml` - Contains BigQuery credentials
- `dbt_health_insurance/target/` - Compiled SQL (generated files)
- `dbt_health_insurance/dbt_packages/` - Downloaded packages
- `dbt_health_insurance/logs/` - Log files
- `*.json` (except packages.yml, schema.yml, sources.yml) - Service account keys
- `.env` files - Environment variables
- `.DS_Store` - macOS system files

### **✅ Included (Correct - Safe to commit):**
- All `.sql` model files
- `schema.yml` and `sources.yml` - Documentation
- `dbt_project.yml` - Project configuration
- `packages.yml` - Package dependencies
- All documentation (README, guides)
- `.gitignore` and `.gitattributes`

---

## 🎨 Optional: Enhance Your Repository

### **Add Topics (Tags)**

On GitHub, click **"Add topics"** and add:
- `dbt`
- `bigquery`
- `data-engineering`
- `etl`
- `data-quality`
- `data-warehouse`
- `python`
- `sql`

### **Add Repository Description**

```
Production-ready dbt project for cleaning and transforming health and insurance data.
Features 39+ automated tests, comprehensive data quality validation, and full documentation.
Built with BigQuery following modern ELT best practices.
```

### **Enable GitHub Pages (Optional)**

To serve dbt documentation:

1. Go to Settings → Pages
2. Source: Deploy from a branch
3. Branch: `main` → `/docs`
4. Save

(You'll need to commit dbt docs to `/docs` folder first)

---

## 📝 Add a CONTRIBUTING.md (Optional)

```bash
cat > CONTRIBUTING.md << 'EOF'
# Contributing Guide

This is an academic project for HWR Berlin's Data Warehouse course.

## How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Make your changes
4. Run tests: `cd dbt_health_insurance && dbt test`
5. Commit changes (`git commit -m 'Add improvement'`)
6. Push to branch (`git push origin feature/improvement`)
7. Open a Pull Request

## Development Setup

See [QUICKSTART.md](dbt_health_insurance/QUICKSTART.md) for setup instructions.

## Code Standards

- Follow dbt best practices
- Add tests for new models
- Update documentation
- Run `dbt test` before committing
EOF

git add CONTRIBUTING.md
git commit -m "docs: Add contributing guidelines"
git push
```

---

## 🏷️ Create a Release (Optional)

After your first successful push:

```bash
# Tag the current commit
git tag -a v1.0.0 -m "Release v1.0.0: Initial production-ready version

Features:
- 4 staging models (views)
- 4 cleaned models (tables)
- 39+ automated tests
- Comprehensive documentation
- Data quality validation
- Multi-format date parsing
- Header row filtering
- FLOAT64 partitioning fix
"

# Push tags to GitHub
git push origin v1.0.0
```

Then on GitHub:
1. Go to Releases → Create a new release
2. Choose tag: `v1.0.0`
3. Title: `v1.0.0 - Initial Release`
4. Description: Copy from tag message
5. Publish release

---

## 🔄 Future Updates

When you make changes:

```bash
# Check what changed
git status

# Stage changes
git add .

# Commit with descriptive message
git commit -m "fix: Update health_insurance_person_cleaned to filter header rows"

# Push to GitHub
git push
```

### **Commit Message Convention**

Use conventional commits:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `refactor:` Code refactoring
- `test:` Adding tests
- `chore:` Maintenance tasks

**Examples:**
```bash
git commit -m "feat: Add blood pressure parsing to sleep_health model"
git commit -m "fix: Handle FLOAT64 partitioning error in smartwatch model"
git commit -m "docs: Update README with installation instructions"
git commit -m "test: Add uniqueness test for person_id"
```

---

## 📊 Repository Stats

After setup, your repository will have:

- **~4,300 lines of code**
- **28 files**
- **SQL:** Primary language (dbt models)
- **YAML:** Configuration and tests
- **Markdown:** Documentation

---

## 🎓 Portfolio Tips

Make your repository stand out:

1. **Pin to Profile:** Pin this repo on your GitHub profile
2. **Add README Badge:** Already included (dbt, BigQuery badges)
3. **Write Good Commit Messages:** Follow conventional commits
4. **Document Everything:** README, inline comments, dbt docs
5. **Show Results:** Include data quality metrics in README

---

## ✅ Checklist

Before sharing your repository:

- [ ] Pushed to GitHub successfully
- [ ] README displays correctly
- [ ] No sensitive files committed (check `.gitignore`)
- [ ] Repository is public (if using for portfolio)
- [ ] Topics/tags added
- [ ] Description added
- [ ] License chosen (optional)

---

## 🆘 Troubleshooting

### **Error: remote origin already exists**

```bash
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/health-insurance-data-warehouse.git
```

### **Error: failed to push**

```bash
# Pull first (if repo was initialized with README)
git pull origin main --allow-unrelated-histories

# Then push
git push -u origin main
```

### **Wrong files committed**

```bash
# Remove from staging
git rm --cached path/to/file

# Add to .gitignore
echo "path/to/file" >> .gitignore

# Commit
git commit -m "chore: Remove sensitive file from tracking"
git push
```

---

**Your repository is ready! 🎉**

Happy coding and best of luck with your Data Warehouse course!
