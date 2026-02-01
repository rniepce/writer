# Writer - Railway Deployment Guide

## Prerequisites
- A Railway account ([railway.app](https://railway.app))
- Your repository pushed to GitHub

## Deployment Steps (Monorepo)

For monorepos, you deploy each service (backend/frontend) separately in Railway:

### 1. Deploy Backend Service
1. Go to Railway Dashboard → **New Project** → **Deploy from GitHub repo**
2. Select `writer` repo
3. Click **Configure** → Set **Root Directory** to `/backend`
4. Railway will detect `railway.toml` and use Docker
5. Set environment variables (see below)

### 2. Deploy Frontend Service
1. In the same Railway project, click **+ New Service** → **GitHub repo**
2. Select `writer` repo again
3. Set **Root Directory** to `/frontend`
4. Set `NEXT_PUBLIC_API_URL` to the backend service URL

### 3. Set Environment Variables

**Backend (`/backend`):**
| Variable | Value |
|---|---|
| `ANTHROPIC_API_KEY` | `your_anthropic_key` |
| `GOOGLE_API_KEY` | `your_google_key` |
| `OPENAI_API_KEY` | `your_openai_key` |

**Frontend (`/frontend`):**
| Variable | Value |
|---|---|
| `NEXT_PUBLIC_API_URL` | `https://<backend-service>.up.railway.app` |

## Project Structure
```
writer/
├── backend/
│   ├── Dockerfile
│   ├── railway.toml      # Per-service Railway config
│   └── ...
├── frontend/
│   ├── Dockerfile
│   ├── railway.toml      # Per-service Railway config
│   └── ...
```

