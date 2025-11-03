import json
import os
import urllib3

def lambda_handler(event, context):
    
    print(f"Iniciando purge manual de prefixos...")

    # 1. Obter segredos das variáveis de ambiente
    api_token   = os.environ.get('CLOUDFLARE_API_TOKEN')
    zone_id     = os.environ.get('CLOUDFLARE_ZONE_ID')
    prefixes_str = os.environ.get('CLOUDFLARE_PREFIXES') # ex: "site1.com/,site2.com/"

    if not all([api_token, zone_id, prefixes_str]):
        print("ERRO: Variáveis de ambiente CLOUDFLARE_* não configuradas. Abortando.")
        return {
            'statusCode': 500,
            'body': json.dumps('Erro interno: Variáveis de ambiente não configuradas.')
        }

    # 2. Converter a string de prefixos em uma lista
    try:
        # Remove espaços em branco e itens vazios se a vírgula estiver no final
        list_of_prefixes = [p.strip() for p in prefixes_str.split(',') if p.strip()]
        if not list_of_prefixes:
            raise ValueError("Lista de prefixos está vazia.")
    except Exception as e:
        print(f"ERRO: Falha ao processar CLOUDFLARE_PREFIXES. Valor: '{prefixes_str}'. Erro: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps('Erro interno: Falha ao processar lista de prefixos.')
        }

    http = urllib3.PoolManager()
    api_endpoint = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/purge_cache"
    headers = {
        "Authorization": f"Bearer {api_token}", 
        "Content-Type": "application/json"
    }
    
    try:
        # 3. Montar o payload com a lista de prefixos
        payload = json.dumps({"prefixes": list_of_prefixes})
        
        print(f"Enviando solicitação de purge para os prefixos: {list_of_prefixes}")
        response = http.request('POST', api_endpoint, body=payload, headers=headers)
        response_data = json.loads(response.data.decode('utf-8'))

        # 4. Verificar o sucesso
        if response.status != 200 or not response_data.get("success"):
            print(f"ERRO: Falha no purge do Cloudflare (HTTP {response.status}). Resposta: {response_data}")
            raise Exception(f"Falha no purge do Cloudflare: {response_data.get('errors')}")
        
        print("Solicitação de purge para prefixos enviada com sucesso.")
        return {
            'statusCode': 200,
            'body': json.dumps(f'Cache limpo com sucesso para {len(list_of_prefixes)} prefixo(s).')
        }

    except Exception as e:
        print(f"ERRO GERAL NA EXECUÇÃO: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Erro ao processar a solicitação: {str(e)}')
        }