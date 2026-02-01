# Writer - Railway Deployment Guide

## Prerequisites
- A Railway account ([railway.app](https://railway.app))
- Your repository pushed to GitHub

## Deployment Steps

### 1. Create a New Project on Railway
1. Go to Railway Dashboard
2. Click **New Project** → **Deploy from GitHub repo**
3. Select your `writer` repository

### 2. Configure Services (Monorepo Setup)
Railway will detect the `railway.toml` file. If not, manually create two services:

**Backend Service:**
- Root Directory: `/backend`
- Builder: Docker

**Frontend Service:**
- Root Directory: `/frontend`
- Builder: Docker

### 3. Set Environment Variables
Go to each service's **Variables** tab:

**Backend (`backend` service):**
| Variable | Value |
|---|---|
| `ANTHROPIC_API_KEY` | `your_anthropic_key` |
| `GOOGLE_API_KEY` | `your_google_key` |
| `OPENAI_API_KEY` | `your_openai_key` |
| `PORT` | `8000` |

**Frontend (`frontend` service):**
| Variable | Value |
|---|---|
| `NEXT_PUBLIC_API_URL` | `https://<backend-service-name>.up.railway.app` |
| `PORT` | `3000` |

### 4. Deploy
Railway will automatically build and deploy both services.

### 5. Get Your URLs
- Backend: `https://<backend-service>.up.railway.app`
- Frontend: `https://<frontend-service>.up.railway.app`

## Project Structure
```
writer/
├── backend/
│   ├── Dockerfile          # Python/FastAPI container
│   ├── requirements.txt    # Python dependencies
│   ├── main.py             # FastAPI entrypoint
│   └── orchestrator.py     # Tripartite Intelligence
├── frontend/
│   ├── Dockerfile          # Next.js container
│   ├── next.config.ts      # Standalone output enabled
│   └── package.json
└── railway.toml            # Railway service configuration
```
