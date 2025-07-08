#!/usr/bin/env node
/**
 * Simple script to create Cognito User Pool and Client
 * Run with: node create-cognito.js
 */

const { CognitoIdentityProviderClient, CreateUserPoolCommand, CreateUserPoolClientCommand } = require("@aws-sdk/client-cognito-identity-provider");

async function createCognitoResources() {
    const client = new CognitoIdentityProviderClient({ region: "us-east-1" });
    
    try {
        console.log("🔧 Creating Cognito User Pool...");
        
        // Create User Pool
        const userPoolParams = {
            PoolName: "order-receiver-dev",
            AutoVerifiedAttributes: ["email"],
            UsernameAttributes: ["email"],
            Policies: {
                PasswordPolicy: {
                    MinimumLength: 8,
                    RequireUppercase: false,
                    RequireLowercase: false,
                    RequireNumbers: false,
                    RequireSymbols: false
                }
            },
            Schema: [
                {
                    Name: "email",
                    Required: true,
                    Mutable: true
                }
            ],
            AdminCreateUserConfig: {
                AllowAdminCreateUserOnly: false
            }
        };

        const userPoolResult = await client.send(new CreateUserPoolCommand(userPoolParams));
        const userPoolId = userPoolResult.UserPool.Id;
        
        console.log(`✅ User Pool created: ${userPoolId}`);

        // Create User Pool Client
        const clientParams = {
            UserPoolId: userPoolId,
            ClientName: "order-receiver-flutter-client",
            ExplicitAuthFlows: [
                "ALLOW_USER_PASSWORD_AUTH",
                "ALLOW_REFRESH_TOKEN_AUTH",
                "ALLOW_USER_SRP_AUTH"
            ],
            GenerateSecret: false,
            RefreshTokenValidity: 30,
            AccessTokenValidity: 24,
            IdTokenValidity: 24
        };

        const clientResult = await client.send(new CreateUserPoolClientCommand(clientParams));
        const clientId = clientResult.UserPoolClient.ClientId;
        
        console.log(`✅ User Pool Client created: ${clientId}`);
        
        console.log("\n🎉 Cognito setup complete!");
        console.log("\nAdd these values to your configuration:");
        console.log(`COGNITO_USER_POOL_ID=${userPoolId}`);
        console.log(`COGNITO_USER_POOL_CLIENT_ID=${clientId}`);
        console.log(`COGNITO_REGION=us-east-1`);
        
        return { userPoolId, clientId };
        
    } catch (error) {
        console.error("❌ Error creating Cognito resources:", error);
        if (error.name === "ResourceConflictException") {
            console.log("💡 User pool might already exist. Check your AWS Console.");
        }
        throw error;
    }
}

if (require.main === module) {
    createCognitoResources().catch(console.error);
}

module.exports = { createCognitoResources };
