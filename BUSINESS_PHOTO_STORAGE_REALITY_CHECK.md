# Business Photo Storage Implementation Plan

## Current Status: ❌ NOT IMPLEMENTED
The DynamoDB analysis shows NO business_photo_url fields in any records.

## What Needs to be Done:

### 1. 🪣 Create S3 Bucket for Photo Storage
```yaml
# Add to serverless.yml
resources:
  Resources:
    BusinessPhotosBucket:
      Type: AWS::S3::Bucket
      Properties:
        BucketName: order-receiver-business-photos-${self:provider.stage}
        PublicAccessBlockConfiguration:
          BlockPublicAcls: false
          BlockPublicPolicy: false
          IgnorePublicAcls: false
          RestrictPublicBuckets: false
        CorsConfiguration:
          CorsRules:
            - AllowedHeaders: ['*']
              AllowedMethods: [GET, POST, PUT]
              AllowedOrigins: ['*']
```

### 2. 🔧 Fix Image Upload Handler
Current handler returns MOCK URLs - needs to actually upload to S3:

```javascript
// backend/functions/upload/image_upload_handler.js
const AWS = require('aws-sdk');
const s3 = new AWS.S3();

const uploadToS3 = async (imageBuffer, key) => {
  const params = {
    Bucket: process.env.BUSINESS_PHOTOS_BUCKET,
    Key: key,
    Body: imageBuffer,
    ContentType: 'image/jpeg',
    ACL: 'public-read'
  };
  
  const result = await s3.upload(params).promise();
  return result.Location;
};
```

### 3. 📊 Update Database Schema
Add business_photo_url field to DynamoDB business records:

```javascript
// In registration handler
const businessItem = {
  // ...existing fields...
  business_photo_url: actualS3Url, // Real S3 URL instead of mock
};
```

### 4. 🔄 Migration Script
Update existing businesses to include business_photo_url field (initially null).

## Implementation Priority:
1. **HIGH**: Create S3 bucket configuration
2. **HIGH**: Fix image upload handler to use real S3
3. **MEDIUM**: Update registration to store real photo URLs
4. **LOW**: Migrate existing business records

## Current Frontend Status:
✅ Ready to display photos when backend provides real URLs
✅ Graceful fallback to default icons when no photos
✅ Loading states and error handling implemented
