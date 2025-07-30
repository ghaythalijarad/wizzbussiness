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
        ContentType: contentType,
        ACL: 'public-read'  // Ensure images are publicly accessible
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
        // Handle API Gateway binary data properly
        let bodyBuffer;
        if (event.isBase64Encoded) {
            // API Gateway encodes binary data as base64
            bodyBuffer = Buffer.from(event.body, 'base64');
        } else {
            // For multipart form data, treat as binary even when not base64 encoded
            // This prevents UTF-8 corruption of binary image data
            bodyBuffer = Buffer.from(event.body, 'binary');
        }
        
        console.log(`Event body length: ${event.body ? event.body.length : 0}`);
        console.log(`Body buffer length: ${bodyBuffer.length}`);
        console.log(`Is base64 encoded: ${event.isBase64Encoded}`);
        console.log(`Body buffer first 20 bytes:`, bodyBuffer.slice(0, 20));
        
        busboy.write(bodyBuffer);
        busboy.end();
    });
};

exports.handler = async (event) => {
    console.log('Image Upload Handler - Event:', JSON.stringify(event, null, 2));

    // Handle Base64 encoded request body
    let requestBody = event.body;
    if (event.isBase64Encoded && requestBody) {
        try {
            requestBody = Buffer.from(requestBody, 'base64').toString('utf-8');
            console.log('📝 Decoded Base64 request body');
        } catch (decodeError) {
            console.error('❌ Failed to decode Base64 body:', decodeError);
        }
    }

    const { httpMethod, path, headers } = event;
    const body = requestBody; // Use decoded body

    try {
        // Handle document and image uploads
        if (httpMethod === 'POST' && path.includes('/upload/')) {
            
            // Determine upload type based on path
            let uploadType = 'product-image'; // default
            let folderName = 'product-images';
            
            if (path.includes('/upload/business-photo')) {
                uploadType = 'business-photo';
                folderName = 'business-photos';
            } else if (path.includes('/upload/business-license')) {
                uploadType = 'business-license';
                folderName = 'business-documents/licenses';
            } else if (path.includes('/upload/owner-identity')) {
                uploadType = 'owner-identity';
                folderName = 'business-documents/identities';
            } else if (path.includes('/upload/health-certificate')) {
                uploadType = 'health-certificate';
                folderName = 'business-documents/health-certificates';
            } else if (path.includes('/upload/owner-photo')) {
                uploadType = 'owner-photo';
                folderName = 'business-documents/owner-photos';
            } else if (path.includes('/upload/product-image')) {
                uploadType = 'product-image';
                folderName = 'product-images';
            }
            
            console.log(`Upload type detected: ${uploadType}, folder: ${folderName}`);
            
            if (!body) {
                return createResponse(400, {
                    success: false,
                    message: 'No file data provided'
                });
            }

            let imageBuffer;
            let contentType = 'image/jpeg';

            // Check if this is multipart form data
            const contentTypeHeader = headers['content-type'] || headers['Content-Type'] || '';
            const isMultipart = contentTypeHeader.toLowerCase().includes('multipart/form-data');

            console.log(`Content-Type: ${contentTypeHeader}`);
            console.log(`Is multipart: ${isMultipart}`);
            console.log(`Body length: ${body ? body.length : 0}`);

            if (isMultipart) {
                try {
                    // Handle multipart form data (from Flutter)
                    console.log('Processing multipart form data with busboy');
                    
                    const { fields, files } = await parseMultipartForm(event);
                    console.log('Parsed fields:', Object.keys(fields));
                    console.log('Parsed files:', Object.keys(files));
                    
                    if (!files.image) {
                        console.error('Available files:', Object.keys(files));
                        throw new Error('No image file found in multipart form. Available: ' + Object.keys(files).join(', '));
                    }
                    
                    imageBuffer = files.image.buffer;
                    contentType = files.image.mimeType || 'image/jpeg';
                    
                    console.log(`Image received: ${imageBuffer.length} bytes, type: ${contentType}`);

                } catch (multipartError) {
                    console.error('Failed to parse multipart data:', multipartError);
                    console.error('Event headers:', JSON.stringify(headers, null, 2));
                    return createResponse(400, {
                        success: false,
                        message: 'Invalid multipart form data: ' + multipartError.message
                    });
                }
            } else {
                // Handle base64 JSON data (legacy format)
                console.log('Processing as base64/JSON data');
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
                    console.log('JSON parse failed, checking if body is direct base64...');
                    // If JSON parsing fails, assume the body is the image data directly
                    if (typeof body === 'string' && body.startsWith('data:')) {
                        imageData = body;
                    } else {
                        console.error('Body does not appear to be valid JSON or base64:', body.substring(0, 100));
                        return createResponse(400, {
                            success: false,
                            message: 'Invalid request body format. Expected JSON with image data or direct base64.'
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

            // Generate unique filename with proper extension based on content type
            const imageId = uuidv4();
            let fileExtension = 'jpg'; // default
            let finalContentType = contentType;
            
            // Determine file extension and normalize content type - support PDFs for documents
            if (contentType.includes('png') || contentType === 'image/png') {
                fileExtension = 'png';
                finalContentType = 'image/png';
            } else if (contentType.includes('jpeg') || contentType.includes('jpg') || contentType === 'image/jpeg') {
                fileExtension = 'jpg';
                finalContentType = 'image/jpeg';
            } else if (contentType.includes('pdf') || contentType === 'application/pdf') {
                fileExtension = 'pdf';
                finalContentType = 'application/pdf';
            } else {
                // Default to JPEG for unknown types (but log it)
                console.log(`Unknown content type: ${contentType}, defaulting to JPEG`);
                fileExtension = 'jpg';
                finalContentType = 'image/jpeg';
            }
            
            const fileName = `${folderName}/${imageId}.${fileExtension}`;

            console.log(`Uploading file: ${fileName}, Content-Type: ${finalContentType}`);

            try {
                // Upload to S3 with correct content type
                const imageUrl = await uploadToS3(imageBuffer, fileName, finalContentType);
                
                console.log(`${uploadType} uploaded successfully:`, imageUrl);
                
                // Create user-friendly message
                const displayName = uploadType.replace(/-/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
                
                return createResponse(200, {
                    success: true,
                    message: `${displayName} uploaded successfully`,
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