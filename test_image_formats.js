#!/usr/bin/env node

const AWS = require('aws-sdk');

// Initialize S3
const s3 = new AWS.S3({ region: 'us-east-1' });
const bucketName = 'order-receiver-business-photos-dev';

async function analyzeImageFormats() {
    console.log('🔍 Analyzing image formats in S3...\n');
    
    try {
        // List all objects in the bucket
        const response = await s3.listObjectsV2({
            Bucket: bucketName,
            Prefix: 'product-images/'
        }).promise();

        console.log(`Found ${response.Contents.length} product images\n`);
        
        // Sample some recent files to check their metadata
        const recentFiles = response.Contents
            .sort((a, b) => new Date(b.LastModified) - new Date(a.LastModified))
            .slice(0, 10);

        for (const file of recentFiles) {
            try {
                const metadata = await s3.headObject({
                    Bucket: bucketName,
                    Key: file.Key
                }).promise();
                
                const fileExtension = file.Key.split('.').pop();
                const contentType = metadata.ContentType;
                const size = metadata.ContentLength;
                
                console.log(`📁 ${file.Key}`);
                console.log(`   Extension: .${fileExtension}`);
                console.log(`   Content-Type: ${contentType}`);
                console.log(`   Size: ${(size / 1024).toFixed(2)} KB`);
                console.log(`   ⚠️  Mismatch: ${contentType !== `image/${fileExtension === 'jpg' ? 'jpeg' : fileExtension}` ? 'YES' : 'NO'}`);
                console.log('');
                
            } catch (error) {
                console.error(`❌ Error getting metadata for ${file.Key}:`, error.message);
            }
        }

        // Summary statistics
        const jpgFiles = response.Contents.filter(item => item.Key.endsWith('.jpg')).length;
        const pngFiles = response.Contents.filter(item => item.Key.endsWith('.png')).length;
        
        console.log('📊 Summary:');
        console.log(`   📷 .jpg files: ${jpgFiles}`);
        console.log(`   🖼️  .png files: ${pngFiles}`);
        console.log(`   📁 Total files: ${response.Contents.length}`);
        
    } catch (error) {
        console.error('❌ Error:', error);
    }
}

// Run the analysis
analyzeImageFormats();
