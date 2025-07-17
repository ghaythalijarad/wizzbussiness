// Real S3 image upload handler with multipart support
const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');
const { createResponse } = require('../auth/utils');
const Busboy = require('busboy');

// Initialize S3 client
const s3 = new AWS.S3({ region: process.env.AWS_REGION || 'us-east-1' });

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
        ContentType: contentType
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

// Helper function to parse multipart form data using busboy
const parseMultipartForm = (event) => {
    return new Promise((resolve, reject) => {
        const busboy = Busboy({ 
            headers: {
                'content-type': event.headers['content-type'] || event.headers['Content-Type']
            }
        });
        
        const fields = {};
        const files = {};
        
        busboy.on('field', (fieldname, val) => {
            fields[fieldname] = val;
        });
        
        busboy.on('file', (fieldname, file, info) => {
            const { filename, encoding, mimeType } = info;
            const chunks = [];
            
            file.on('data', (chunk) => {
                chunks.push(chunk);
            });
            
            file.on('end', () => {
                files[fieldname] = {
                    buffer: Buffer.concat(chunks),
                    filename,
                    mimeType
                };
            });
        });
        
        busboy.on('finish', () => {
            resolve({ fields, files });
        });
        
        busboy.on('error', (err) => {
            reject(err);
        });
        
        // Write the body data to busboy
        const bodyBuffer = Buffer.from(event.body, event.isBase64Encoded ? 'base64' : 'utf8');
        busboy.write(bodyBuffer);
        busboy.end();
    });
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

            let imageBuffer;
            let contentType = 'image/jpeg';

            // Check if this is multipart form data
            const isMultipart = headers['content-type'] && headers['content-type'].includes('multipart/form-data');

            if (isMultipart) {
                try {
                    // Handle multipart form data (from Flutter)
                    console.log('Processing multipart form data with busboy');
                    
                    const { fields, files } = await parseMultipartForm(event);
                    console.log('Parsed fields:', fields);
                    console.log('Parsed files:', Object.keys(files));
                    
                    if (!files.image) {
                        throw new Error('No image file found in multipart form');
                    }
                    
                    imageBuffer = files.image.buffer;
                    contentType = files.image.mimeType || 'image/jpeg';
                    
                    console.log(`Image received: ${imageBuffer.length} bytes, type: ${contentType}`);

                } catch (multipartError) {
                    console.error('Failed to parse multipart data:', multipartError);
                    return createResponse(400, {
                        success: false,
                        message: 'Invalid multipart form data: ' + multipartError.message
                    });
                }
            } else {
                // Handle base64 JSON data (legacy format)
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
                    imageBuffer = decodedImage.data;
                    contentType = decodedImage.type;
                } catch (decodeError) {
                    console.error('Failed to decode base64 image:', decodeError);
                    return createResponse(400, {
                        success: false,
                        message: 'Invalid image format. Please provide a valid base64 encoded image.'
                    });
                }
            }

            // Generate unique filename
            const imageId = uuidv4();
            const fileExtension = contentType.includes('png') ? 'png' : 'jpg';
            const fileName = isBusinessPhoto 
                ? `business-photos/${imageId}.${fileExtension}`
                : `product-images/${imageId}.${fileExtension}`;

            try {
                // Upload to S3
                const imageUrl = await uploadToS3(imageBuffer, fileName, contentType);
                
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