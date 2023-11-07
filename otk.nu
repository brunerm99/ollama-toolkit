#!/bin/env nu 
# Interact with OLLaMa API

# Create the url for the OLLaMa API
def create-url [
  endpoint: string # api, generate, etc.
] {
  {
    scheme: http, 
    host: localhost, 
    port: 11434, 
    path: $"api/($endpoint)"
  } | url join
}

# Select model from running models
export def select-model [] -> string {
  http get (create-url "tags") | get models.name | input list
}

# Prompt the model
export def ask [
  prompt: string # Prompt for model
  --stream # Stream data
  --select-model (-s) # Select model from running
] {
  let model = if $select_model { select-model } else { "orca-mini" }
  let response = (http post -t application/json (create-url "generate") {
    model: $model
    prompt: $prompt
    stream: $stream
  })
  $response | 
    merge (
      $response | 
      select ($response | columns | filter {'duration' in $in}) | 
      transpose | 
      update column1 {into duration} | 
      transpose --header-row | into record) | 
    update created_at {into datetime}
}
