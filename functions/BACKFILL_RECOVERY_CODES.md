# Recovery Code Backfill Function

This document describes how to use the one-time Cloud Function to generate recovery codes for all legacy trips.

## What It Does

The `backfillRecoveryCodes` function:
- Iterates through all trips in the Firestore database
- Checks if each trip already has a recovery code
- Generates a 12-digit recovery code for trips that don't have one
- Saves the recovery code to `/trips/{tripId}/recovery/code`
- Returns a detailed summary of the operation

## Prerequisites

1. Firebase CLI installed: `npm install -g firebase-tools`
2. Logged into Firebase: `firebase login`
3. Project selected: `firebase use expensetracker-72f87`

## Usage

### Step 1: Deploy the Function

From the project root directory:

```bash
firebase deploy --only functions:backfillRecoveryCodes
```

This will deploy the function to Firebase Cloud Functions.

### Step 2: Run the Function

#### Option A: Via Firebase Console (Recommended)

1. Go to [Firebase Console](https://console.firebase.google.com/project/expensetracker-72f87/functions)
2. Navigate to **Functions** section
3. Find `backfillRecoveryCodes` in the list
4. Click on the function name
5. Go to the **Testing** tab
6. Click **Run Test**
7. View the response with the summary

#### Option B: Via curl

```bash
curl https://us-central1-expensetracker-72f87.cloudfunctions.net/backfillRecoveryCodes
```

Replace `us-central1` with your actual region if different.

### Step 3: Verify Results

The function returns a JSON response:

```json
{
  "success": true,
  "message": "Recovery code backfill completed",
  "generated": 5,
  "skipped": 2,
  "total": 7,
  "results": [
    {
      "tripId": "abc123",
      "tripName": "Vietnam Trip",
      "status": "generated",
      "code": "1234-5678-9012"
    },
    {
      "tripId": "def456",
      "tripName": "Test Trip",
      "status": "skipped"
    }
  ]
}
```

## Response Fields

- `success`: Whether the operation completed successfully
- `generated`: Number of recovery codes generated
- `skipped`: Number of trips that already had recovery codes
- `total`: Total number of trips processed
- `results`: Array of per-trip results with:
  - `tripId`: The trip ID
  - `tripName`: The trip name
  - `status`: `generated`, `skipped`, or `error`
  - `code`: The generated recovery code (only for `generated` status)

## Safety Features

- **Idempotent**: Safe to run multiple times - skips trips that already have recovery codes
- **Non-destructive**: Only creates new recovery codes, never modifies existing ones
- **Detailed logging**: Logs every step to Cloud Functions logs
- **Error handling**: Continues processing other trips if one fails

## Viewing Logs

To see detailed execution logs:

```bash
firebase functions:log --only backfillRecoveryCodes
```

Or view in Firebase Console → Functions → Logs tab

## After Backfill

Once the backfill is complete:

1. **Verify in Firestore Console**: Check that trips have recovery codes at `/trips/{tripId}/recovery/code`
2. **Test recovery code flow**: Try using a recovery code to join a trip
3. **Optional: Delete the function** (if you want to save costs):
   ```bash
   firebase functions:delete backfillRecoveryCodes
   ```

## Important Notes

- **One-time operation**: This should only be run once for legacy trips
- **New trips**: Automatically get recovery codes on creation (no backfill needed)
- **Security**: The function uses admin privileges and should not be exposed publicly
- **Cost**: Minimal - one-time function execution (likely under $0.01)

## Troubleshooting

### Function fails with permission error
- Ensure Firebase Admin SDK has proper permissions
- Check Firestore security rules allow admin writes

### Some trips show "error" status
- Check Cloud Functions logs for specific error details
- Verify those trips exist and are accessible

### Function times out
- For very large databases (100+ trips), consider adding pagination
- Increase function timeout in firebase.json if needed

## Future Considerations

After all legacy trips have recovery codes, you can:
1. Remove the backfill function to reduce deployed code
2. Keep it for historical reference
3. Archive this documentation

---

**Last Updated**: 2025-10-29
**Related Feature**: Device Pairing & Recovery Codes (004-device-pairing)
