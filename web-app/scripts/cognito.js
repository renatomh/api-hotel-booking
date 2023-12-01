const config={
    cognito:{
        identityPoolId:"us-east-2_lYwa6JSoj",
        cognitoDomain:"hotel-booking-users.auth.us-east-2.amazoncognito.com",
        appId:"7sfpapugas25g9gak2ar86pm3d"
    }
}

var cognitoApp={
    auth:{},
    Init: function()
    {

        var authData = {
            ClientId : config.cognito.appId,
            AppWebDomain : config.cognito.cognitoDomain,
            TokenScopesArray : ['email', 'openid', 'profile'],
            RedirectUriSignIn : 'https://hotel-booking-mhsw.netlify.app/',
            RedirectUriSignOut : 'https://hotel-booking-mhsw.netlify.app/',
            UserPoolId : config.cognito.identityPoolId, 
            AdvancedSecurityDataCollectionFlag : false,
                Storage: null
        };

        cognitoApp.auth = new AmazonCognitoIdentity.CognitoAuth(authData);
        cognitoApp.auth.userhandler = {
            onSuccess: function(result) {
              
            },
            onFailure: function(err) {
            }
        };
    }
}