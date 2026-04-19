from google import genai

client = genai.Client(
    api_key="AIzaSyC9nc3BtfwtHawxgYUSF9imzNtyHyKEy1c"
)

response = client.models.generate_content(
    model="gemini-flash-latest",
    # model="gemini-2.5-flash-lite",
    contents="Di hola en una  palabra"
)

print(response.text)