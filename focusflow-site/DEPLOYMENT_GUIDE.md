# FocusFlow Website Deployment Guide

This guide will help you deploy the FocusFlow website to AWS Amplify as a **completely separate deployment** from the softcomputers-site.

## ✅ Pre-Deployment Checklist

- [x] `amplify.yml` configured for `focusflow-site` subdirectory
- [x] `next.config.ts` has `output: 'export'` for static export
- [x] Build tested successfully (`npm run build`)
- [x] All TypeScript errors resolved
- [x] Domain `focusflowbepresent.com` ready for DNS configuration

## Step 1: Repository Structure

Your repository structure is:
```
FocusFlow/
├── focusflow-site/     ← FocusFlow website (this one)
├── softcomputers-site/ ← Soft Computers website (untouched)
└── ...
```

The `amplify.yml` is configured to build from the `focusflow-site/` subdirectory.

## Step 2: Create AWS Amplify App

1. **Go to AWS Amplify Console**
   - Navigate to: https://console.aws.amazon.com/amplify
   - Click **"New app"** → **"Host web app"**

2. **Connect Repository**
   - Choose your Git provider (GitHub, GitLab, Bitbucket, etc.)
   - Select the repository containing the FocusFlow project
   - Select the branch you want to deploy (usually `main` or `master`)
   - **Important**: This is a NEW app, separate from your softcomputers-site app

3. **Configure Build Settings**
   - AWS Amplify should auto-detect the `amplify.yml` file from `focusflow-site/amplify.yml`
   - If it doesn't auto-detect, click "Edit" and set:
     - **App root**: Leave empty (or `/` if that's the repo root)
     - **Build settings**: Use the `amplify.yml` from `focusflow-site/` directory
   - The build configuration is:
     ```yaml
     version: 1
     frontend:
       phases:
         preBuild:
           commands:
             - cd focusflow-site
             - npm ci
         build:
           commands:
             - cd focusflow-site
             - npm run build
       artifacts:
         baseDirectory: focusflow-site/out
         files:
           - '**/*'
       cache:
         paths:
           - focusflow-site/node_modules/**/*
     ```

4. **Review and Deploy**
   - Review all settings
   - Click **"Save and deploy"**
   - Wait for the build to complete (usually 3-5 minutes)

## Step 3: Configure Custom Domain

1. **In Amplify Console**
   - Go to your app → **"Domain management"** (left sidebar)
   - Click **"Add domain"**
   - Enter: `focusflowbepresent.com`
   - Click **"Configure domain"**

2. **DNS Configuration**
   - AWS Amplify will provide DNS records (usually CNAME records)
   - You'll see something like:
     ```
     Type: CNAME
     Name: (leave empty or @)
     Value: xxxxx.cloudfront.net
     ```
   - Go to your domain registrar (where you bought `focusflowbepresent.com`)
   - Add the DNS records provided by Amplify
   - **Important**: This is separate from softcomputers.ca - don't touch those DNS records

3. **SSL Certificate**
   - AWS Amplify automatically provisions SSL certificates via AWS Certificate Manager
   - This happens automatically once DNS is configured correctly
   - Wait for certificate validation (usually 5-30 minutes)
   - You'll see a green checkmark when it's ready

## Step 4: Environment Variables (Optional)

If you need any environment variables:
1. Go to **App settings** → **Environment variables**
2. Add variables like:
   - `NEXT_PUBLIC_SITE_URL=https://focusflowbepresent.com`
   - Any other public variables your app needs
3. **Redeploy** after adding variables

## Step 5: Verify Deployment

1. **Check Build Status**
   - Ensure the build completed successfully (green checkmark)
   - Check build logs for any errors
   - All pages should show as "Static" (○)

2. **Test the Site**
   - Visit the Amplify-provided URL first: `https://main.xxxxx.amplifyapp.com`
   - Once domain is configured, test: `https://focusflowbepresent.com`

3. **Test All Pages**
   - ✅ Home: `https://focusflowbepresent.com/`
   - ✅ Features: `https://focusflowbepresent.com/features`
   - ✅ Pricing: `https://focusflowbepresent.com/pricing`
   - ✅ About: `https://focusflowbepresent.com/about`
   - ✅ Sign In: `https://focusflowbepresent.com/signin`
   - ✅ Privacy: `https://focusflowbepresent.com/privacy`
   - ✅ Terms: `https://focusflowbepresent.com/terms`

## Important Notes

- ✅ This is a **completely separate deployment** from softcomputers-site
- ✅ The softcomputers-site will remain **completely untouched**
- ✅ Both sites can run independently on different domains
- ✅ Each has its own:
  - Amplify app
  - Domain (`focusflowbepresent.com` vs `softcomputers.ca`)
  - SSL certificate
  - Build configuration
  - Deployment pipeline

## Troubleshooting

### Build Fails
- **Check build logs** in Amplify console (click on the failed build)
- Common issues:
  - Missing dependencies → Check `package.json`
  - TypeScript errors → Fix all TS errors before deploying
  - Node version → Amplify uses Node 18 by default (should be fine)

### Domain Not Working
- **Verify DNS records** are correct in your domain registrar
- **Wait for DNS propagation** (can take up to 48 hours, usually 5-30 minutes)
- Use `dig focusflowbepresent.com` or `nslookup focusflowbepresent.com` to check
- Ensure SSL certificate is validated (green checkmark in Amplify)

### Static Export Issues
- Ensure `next.config.ts` has `output: 'export'` ✅ (already done)
- Check that no server-side features are used (all pages should be static)
- Verify `images.unoptimized: true` is set ✅ (already done)

### 404 Errors
- Check that `trailingSlash: true` is set in `next.config.ts` ✅ (already done)
- Verify all routes are exported correctly

## Next Steps After Deployment

1. ✅ Test all functionality on the live site
2. ✅ Update any hardcoded URLs if needed
3. ✅ Set up monitoring (optional - CloudWatch in AWS)
4. ✅ Configure custom 404 page if needed
5. ✅ Set up redirects if needed (in Amplify console → Rewrites and redirects)

## Quick Reference

- **Amplify Console**: https://console.aws.amazon.com/amplify
- **Domain**: `focusflowbepresent.com`
- **Build Directory**: `focusflow-site/out`
- **Separate from**: `softcomputers.ca` (completely independent)

---

**Ready to deploy?** Follow Steps 2-5 above, and your FocusFlow website will be live at `focusflowbepresent.com`! 🚀
