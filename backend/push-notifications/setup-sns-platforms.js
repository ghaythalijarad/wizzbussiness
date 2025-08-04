#!/usr/bin/env node

/**
 * Setup SNS Platform Applications for iOS (APNS) and Android (FCM)
 * 
 * This script creates SNS platform applications that can be used to send
 * push notifications to iOS and Android devices via Firebase Cloud Messaging
 */

const AWS = require('aws-sdk');
const fs = require('fs');
const path = require('path');

// Configure AWS
const sns = new AWS.SNS({ region: 'us-east-1' });

async function createAndroidPlatformApplication() {
    try {
        console.log('Creating Android (FCM) Platform Application...');
        
        const fcmServerKey = process.env.FCM_SERVER_KEY;
        if (!fcmServerKey) {
            throw new Error('FCM_SERVER_KEY environment variable is required');
        }

        const params = {
            Name: 'OrderReceiver-Android-FCM',
            Platform: 'GCM', // Google Cloud Messaging (includes FCM)
            Attributes: {
                'PlatformCredential': fcmServerKey
            }
        };

        const result = await sns.createPlatformApplication(params).promise();
        console.log('Android Platform Application created:', result.PlatformApplicationArn);
        
        return result.PlatformApplicationArn;
    } catch (error) {
        console.error('Error creating Android platform application:', error);
        throw error;
    }
}

async function createIOSPlatformApplication() {
    try {
        console.log('Creating iOS (APNS) Platform Application...');
        
        const apnsCertificatePath = process.env.APNS_CERTIFICATE_PATH;
        const apnsPrivateKeyPath = process.env.APNS_PRIVATE_KEY_PATH;
        const apnsEnvironment = process.env.APNS_ENVIRONMENT || 'APNS_SANDBOX'; // APNS or APNS_SANDBOX
        
        if (!apnsCertificatePath || !apnsPrivateKeyPath) {
            console.log('APNS certificate paths not provided, skipping iOS platform application');
            return null;
        }

        const certificate = fs.readFileSync(apnsCertificatePath, 'utf8');
        const privateKey = fs.readFileSync(apnsPrivateKeyPath, 'utf8');

        const params = {
            Name: 'OrderReceiver-iOS-APNS',
            Platform: apnsEnvironment,
            Attributes: {
                'PlatformCertificate': certificate,
                'PlatformPrincipal': privateKey
            }
        };

        const result = await sns.createPlatformApplication(params).promise();
        console.log('iOS Platform Application created:', result.PlatformApplicationArn);
        
        return result.PlatformApplicationArn;
    } catch (error) {
        console.error('Error creating iOS platform application:', error);
        throw error;
    }
}

async function listExistingPlatformApplications() {
    try {
        const result = await sns.listPlatformApplications().promise();
        console.log('\nExisting Platform Applications:');
        result.PlatformApplications.forEach(app => {
            console.log(`- ${app.PlatformApplicationArn}`);
        });
        return result.PlatformApplications;
    } catch (error) {
        console.error('Error listing platform applications:', error);
        return [];
    }
}

async function main() {
    console.log('Setting up SNS Platform Applications for Push Notifications...\n');

    try {
        // List existing applications first
        await listExistingPlatformApplications();

        // Create platform applications
        const androidArn = await createAndroidPlatformApplication();
        const iosArn = await createIOSPlatformApplication();

        // Save ARNs to environment file
        const envContent = `
# SNS Platform Application ARNs
ANDROID_PLATFORM_APPLICATION_ARN=${androidArn}
${iosArn ? `IOS_PLATFORM_APPLICATION_ARN=${iosArn}` : '# iOS Platform Application not created - APNS certificates not provided'}

# Add these to your serverless.yml environment variables
# and Lambda function environment variables
`;

        fs.writeFileSync(path.join(__dirname, 'platform-arns.env'), envContent);
        console.log('\nPlatform Application ARNs saved to platform-arns.env');

        console.log('\n✅ SNS Platform Applications setup completed!');
        console.log('\nNext steps:');
        console.log('1. Add the ARNs to your serverless.yml environment variables');
        console.log('2. Update your Lambda functions to use these ARNs');
        console.log('3. Test push notifications');

    } catch (error) {
        console.error('Setup failed:', error);
        process.exit(1);
    }
}

// Run the setup
if (require.main === module) {
    main();
}

module.exports = {
    createAndroidPlatformApplication,
    createIOSPlatformApplication,
    listExistingPlatformApplications
};
