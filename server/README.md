


curl -X 'GET' \
  'http://127.0.0.1:8000/echo/?message=HelloWorld' \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $TOKEN"



uvicorn src.main:app --reload
