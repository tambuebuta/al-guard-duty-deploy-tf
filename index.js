const AWS = require('aws-sdk');
const response = require('cfn-response');


function encrypt(event, context) {
    const params = {
        KeyId: event.ResourceProperties.KeyId,
        Plaintext: event.ResourceProperties.Plaintext
    };
    const kms = new AWS.KMS();
    kms.encrypt(params, function(err, data) {
        if (err) {
            console.log(err, err.stack); // an error occurred
            return response.send(event, context, response.FAILED);
        }
        var base64 = new Buffer(data.CiphertextBlob).toString('base64');
        var responseData = {
            EncryptedText : base64
        };
        return response.send(event, context, response.SUCCESS, responseData);
    });
}


exports.handler = (event, context, callback) => {
    if (event.ResourceType == 'AWS::CloudFormation::CustomResource' &&
        event.RequestType == 'Create') {
        return encrypt(event, context);
    }
    return response.send(event, context, response.SUCCESS);
}