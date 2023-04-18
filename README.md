# candle
Candle is a haptic compass empowering visually impaired users through intuitive navigation. Harnessing advanced haptic feedback, it delivers real-time direction for confident exploration. Discover a new world of independence with Candle's groundbreaking approach to accessible travel.


```
curl http://localhost:5000/createTestUser

curl -X POST -H "Content-Type: application/json" -d '{"user_id": "92a797f2-74f0-4c60-a584-d225a6a2fc98"}' http://localhost:5000/startRecording


f24bf17b-73f1-40e5-9ef2-5947455e3869


curl --request POST \
  --url http://localhost:5000/record \
  --header 'Content-Type: application/json' \
  --data '{
      "latitude": 49.4016,
      "longitude": 8.6819,
      "route": "f24bf17b-73f1-40e5-9ef2-5947455e3869"
  }'

```