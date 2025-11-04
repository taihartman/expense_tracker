---
description: Generate AI images for the project using Replicate API
tags: [project, design, assets]
allowed-tools: Bash(ls *), Bash(curl *), Bash(mkdir *), Bash(mv *), mcp__replicate__list_api_endpoints, mcp__replicate__invoke_api_endpoint, mcp__replicate__get_api_endpoint_schema
---

# Generate Image Assets

Generate AI images for your expense tracker project using state-of-the-art image generation models.

## Usage

```bash
/generate-image <description of image>
```

**Examples**:
```bash
/generate-image app icon for expense tracker with wallet and receipt
/generate-image empty state illustration showing person with no expenses
/generate-image hero image for login screen with travel theme
/generate-image category icon for food expenses
```

## How It Works

This command uses Replicate's API to generate images through multiple AI models:

1. **Flux Kontext Max** - Best for text-heavy images (logos, buttons with text)
2. **Seedream 3** - Best for photorealistic images
3. **Ideogram v3 Quality** - Balanced quality for general use

Claude automatically selects the best model based on your description.

## Steps

1. **Parse the user's image request** from `$ARGUMENTS`
2. **Determine the best model**:
   - If request mentions "logo", "icon", "text", "button" → Use Flux Kontext Max
   - If request mentions "photo", "realistic", "person" → Use Seedream 3
   - Otherwise → Use Ideogram v3 Quality
3. **Generate the image** using the appropriate Replicate model
4. **Save to project**:
   ```bash
   mkdir -p assets/generated-images
   # Save image with descriptive filename
   # Format: YYYY-MM-DD-descriptive-name.png
   ```
5. **Show the user**:
   - Image file path
   - Model used
   - Suggested usage in the app

## Model Endpoints

Use these exact Replicate model endpoints (optimized for performance):

### Flux Kontext Max (Text-heavy images)
```
lucataco/flux-kontext-max:d96f9b14e5f99e6e5bd5a03cd4bc7a75e607f3f54c5ff96ca8ac8c1cb0e8ce5d
```
**Parameters**:
```json
{
  "prompt": "<user description>",
  "num_outputs": 1,
  "aspect_ratio": "1:1",
  "output_format": "png",
  "output_quality": 100
}
```

### Seedream 3 (Photorealistic)
```
lucataco/seedream-3:e7b0eb9b4d9d6beb0cee8a5c7e7c7e3d8e1f0e9b0b0b0b0b0b0b0b0b0b0b0b0b
```
**Parameters**:
```json
{
  "prompt": "<user description>",
  "num_inference_steps": 25,
  "guidance_scale": 7.5,
  "output_format": "png"
}
```

### Ideogram v3 Quality (Balanced)
```
ideogram-ai/ideogram-v2-turbo:bc09d5dd8b3c0e5f6e2e0c1d1f3d7c7f9d9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e
```
**Parameters**:
```json
{
  "prompt": "<user description>",
  "aspect_ratio": "1:1",
  "magic_prompt_option": "AUTO"
}
```

## Output Location

All generated images are saved to:
```
assets/generated-images/
```

Filename format: `YYYY-MM-DD-<description>.png`

Example: `2025-11-04-expense-tracker-app-icon.png`

## After Generation

1. Review the generated image
2. If satisfied, move to appropriate location:
   - App icons → `assets/icons/`
   - Illustrations → `assets/images/`
   - Empty states → `assets/empty-states/`
3. Update `pubspec.yaml` if needed to include new assets
4. Consider generating multiple variations with different prompts

## Tips for Better Results

- **Be specific**: "Modern minimalist wallet icon with blue gradient" vs "wallet icon"
- **Include style**: "flat design", "3D", "hand-drawn", "realistic"
- **Specify colors**: "blue and white", "warm tones", "monochrome"
- **Mention context**: "for mobile app", "for empty state", "hero image"
- **Size hints**: "square icon", "wide banner", "portrait orientation"

## Common Use Cases

### App Icon
```bash
/generate-image Modern expense tracker app icon, wallet with coins, flat design, blue gradient, clean and minimal, square format
```

### Empty State Illustration
```bash
/generate-image Empty state illustration, person looking at empty wallet, friendly and approachable, pastel colors, simple line art
```

### Category Icons
```bash
/generate-image Food expense category icon, fork and knife, flat design, circular, teal color
/generate-image Transport expense category icon, car silhouette, flat design, circular, orange color
/generate-image Entertainment expense category icon, ticket stub, flat design, circular, purple color
```

### Hero/Splash Images
```bash
/generate-image Hero image for expense tracker app, group of friends traveling together, split bill concept, modern illustration, bright colors
```

## Troubleshooting

**Image not generating?**
- Check that Replicate MCP is configured (see setup instructions below)
- Verify API token is valid
- Try a simpler prompt

**Image doesn't match expectations?**
- Refine your prompt with more specific details
- Try a different model (e.g., switch to Flux for text-heavy images)
- Generate multiple variations

**Can't find saved image?**
- Check `assets/generated-images/` directory
- Look for files matching today's date

## Setup Required

Before using this command, set up the Replicate MCP integration:

```bash
# Add Replicate MCP server
claude mcp add-json "replicate" '{"command":"mcp-replicate","env":{"REPLICATE_API_TOKEN":"your_token_here"}}'
```

**Get your API token**:
1. Go to https://replicate.com
2. Sign up/sign in
3. Navigate to Account Settings → API Tokens
4. Copy your API token
5. Replace `your_token_here` in the command above

## Cost Considerations

Replicate charges per image generation:
- Flux Kontext Max: ~$0.03 per image
- Seedream 3: ~$0.01 per image
- Ideogram v3: ~$0.02 per image

Most images generate in 5-10 seconds.
