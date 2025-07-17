// Real S3 image upload handler
const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');
const { createResponse } = require('../auth/utils');

// Initialize S3 client
const s3 = new AWS.S3({ region: process.env.AWS_REGION || 'eu-north-1' });

// Helper function to upload image to S3
const uploadToS3 = async (imageBuffer, key, contentType = 'image/jpeg') => {
    const bucketName = process.env.BUSINESS_PHOTOS_BUCKET;
    
    if (!bucketName) {
        throw new Error('BUSINESS_PHOTOS_BUCKET environment variable not set');
    }
    
    const params = {
        Bucket: bucketName,
        Key: key,
        Body: imageBuffer,
        ContentType: contentType,
        ACL: 'public-read'
    };
    
    console.log(`Uploading to S3: ${bucketName}/${key}`);
    const result = await s3.upload(params).promise();
    console.log(`S3 upload successful: ${result.Location}`);
    
    return result.Location;
};

// Helper function to decode base64 image
const decodeBase64Image = (dataString) => {
    const matches = dataString.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
    if (!matches || matches.length !== 3) {
        throw new Error('Invalid base64 image data');
    }
    
    return {
        type: matches[1],
        data: Buffer.from(matches[2], 'base64')
    };
};

exports.handler = async (event) => {
    console.log('Image Upload Handler - Event:', JSON.stringify(event, null, 2));

    const { httpMethod, path, headers, body } = event;

    try {
        // Handle business photo upload during registration
        if (httpMethod === 'POST' && (path.includes('/upload/business-photo') || path.includes('/upload/product-image'))) {
            
            // Check if this is a business photo upload
            const isBusinessPhoto = headers['x-upload-type'] === 'business-photo' || 
                                   path.includes('/upload/business-photo') ||
                                   (body && body.includes('business-photo'));
            
            if (!body) {
                return createResponse(400, {
                    success: false,
                    message: 'No image data provided'
                });
            }

            let imageData;
            let parsedBody;

            try {
                parsedBody = JSON.parse(body);
                
                // Handle different body formats
                if (parsedBody.image) {
                    imageData = parsedBody.image;
                } else if (parsedBody.imageData) {
                    imageData = parsedBody.imageData;
                } else if (typeof parsedBody === 'string' && parsedBody.startsWith('data:')) {
                    imageData = parsedBody;
                } else {
                    throw new Error('No image data found in request body');
                }
            } catch (parseError) {
                // If JSON parsing fails, assume the body is the image data directly
                if (typeof body === 'string' && body.startsWith('data:')) {
                    imageData = body;
                } else {
                    return createResponse(400, {
                        success: false,
                        message: 'Invalid request body format'
                    });
                }
            }

            // Decode base64 image
            let decodedImage;
            try {
                decodedImage = decodeBase64Image(imageData);
            } catch (decodeError) {
                console.error('Failed to decode base64 image:', decodeError);
                return createResponse(400, {
                    success: false,
                    message: 'Invalid image format. Please provide a valid base64 encoded image.'
                });
            }

            // Generate unique filename
            const imageId = uuidv4();
            const fileExtension = decodedImage.type.includes('png') ? 'png' : 'jpg';
            const fileName = isBusinessPhoto 
                ? `business-photos/${imageId}.${fileExtension}`
                : `product-images/${imageId}.${fileExtension}`;

            try {
                // Upload to S3
                const imageUrl = await uploadToS3(decodedImage.data, fileName, decodedImage.type);
                
                console.log(`${isBusinessPhoto ? 'Business' : 'Product'} photo uploaded successfully:`, imageUrl);
                
                return createResponse(200, {
                    success: true,
                    message: `${isBusinessPhoto ? 'Business' : 'Product'} photo uploaded successfully`,
                    imageUrl: imageUrl
                });
                
            } catch (uploadError) {
                console.error('S3 upload error:', uploadError);
                return createResponse(500, {
                    success: false,
                    message: 'Failed to upload image to storage',
                    error: uploadError.message
                });
            }
        }

        // Handle other endpoints
        return createResponse(404, {
            success: false,
            message: 'Endpoint not found'
        });

    } catch (error) {
        console.error('Image upload handler error:', error);
        return createResponse(500, {
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
};
