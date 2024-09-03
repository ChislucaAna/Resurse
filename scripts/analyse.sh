#!/bin/bash

# Ensure the NGROK_URL environment variable is set
if [ -z "$NGROK_URL" ]; then
  echo "Error: NGROK_URL environment variable is not set."
  exit 1
fi

# Encode the image in base64 and store it in a variable
test=$(base64 "$1")

# Create a JSON payload and write it to a temporary file
json_payload=$(cat <<EOF
{
  "model": "llava:13b",
  "messages": [
    {
      "role": "user",
      "content": "
        Generate a list of keywords based on the content of the following image. Use the filename to identify the subject of the image and include it in the list.

        **Requirements:**
        1. The image is related to university-level computer science.
        2. The keywords should be in English and consist of computer science or mathematics terms only.
        3. Include possible subject names like mathematics or computer science if relevant.
        4. If the image appears exam-related, include the term exam.
        5. Avoid adding terms not visible or explicitly depicted in the image. Be highly selective and avoid assumptions.
        6. The output should be a comma-separated list of likely terms, ordered by relevance.
        7. Do not add any additional text or context—just the keywords.",
      "images": ["$test"]
    }
  ],
  "stream": false
}
EOF
)

# Write JSON payload to a temporary file
echo "$json_payload" > /tmp/payload.json

# Use curl to send the JSON request with the payload from the file and redirect the output to a file
curl --location "$NGROK_URL/api/chat" \
--header 'Content-Type: application/json' \
--data @/tmp/payload.json > /tmp/response.json

# Extract keywords from the response JSON and write them to aux.txt
jq -r '.choices[0].message.content' /tmp/response.json
