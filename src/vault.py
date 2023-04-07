import boto3
import hvac
import json
import datetime


def lambda_handler(event, context):
    # get credentials from boto3 (default credentials from Lambda)
    session = boto3.Session()
    credentials = session.get_credentials()

    # init the vault client and login
    client = hvac.Client()
    client.auth.aws.iam_login(credentials.access_key, credentials.secret_key, credentials.token, role='vault-lambda-role')

    # read from Vault
    secret_version_response = client.kv.v2.read_secret_version(path='myTestSecret')

    print('Latest version of secret under path "myTestSecret" contains the following keys: {data}'.format(
        data=secret_version_response['data']['data'].keys(),
    ))

    for key in secret_version_response['data']['data'].keys():
        print('the key {keyname} has value: {value}'.format(
            keyname=key,
            value=secret_version_response['data']['data'][key]
        ))

    # write to Vault
    client.secrets.kv.v2.create_or_update_secret(
        path='writeFromLambda',
        secret=dict(pssst='this is secret '+datetime.datetime.now().__str__()),
    )

    return dict(statusCode=200, body=json.dumps(
        'Hello from Lambda! Please have a look to the log of the function and to the newly created secret in vault.'))
