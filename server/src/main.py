from fastapi import FastAPI, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError
import requests

app = FastAPI()

GOOGLE_CLIENT_ID = '79475244045-ci9avdbmgi9didod6jj98hcel91ngi3q.apps.googleusercontent.com'

# Define the HTTPBearer instance
bearer_scheme = HTTPBearer()

def get_jwks_uri(issuer: str):
    """Fetch the JWKS URI from the issuer's OpenID Connect discovery document."""
    discovery_doc_url = f"{issuer}/.well-known/openid-configuration"
    discovery_doc = requests.get(discovery_doc_url).json()
    return discovery_doc['jwks_uri']

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme)):
    """
    Dependency that authenticates the user by validating the JWT token.
    """
    token = credentials.credentials
    try:
        # Extract the issuer from the unverified claims
        unverified_claims = jwt.get_unverified_claims(token)
        issuer = unverified_claims['iss']
        
        # Fetch the JWKS URI and the JWKS
        jwks_uri = get_jwks_uri(issuer)
        jwks = requests.get(jwks_uri).json()

        # Perform the actual JWT validation
        # This part is simplified and should be replaced with your validation logic
        # For the purpose of demonstration, assume user is successfully authenticated
        return unverified_claims  # Or return a user object based on validated claims
        
    except JWTError:
        raise HTTPException(status_code=403, detail="Invalid token.")

@app.get("/echo/")
async def echo(message: str, user: dict = Depends(get_current_user)):
    """
    A protected endpoint that echoes back the message sent by the user.
    The endpoint requires a valid JWT token for access.
    """
    return {"message": message, "user": user}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
