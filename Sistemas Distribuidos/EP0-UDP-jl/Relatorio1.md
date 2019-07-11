# Relatório Sistemas distribuídos
### Entrega 1

Aluno: Gabriel Martins Trettel, 11021916
***


#### Gossip implementado
O protocolo de comunicação Gossip em sistemas distribuídos tem o objetivo de disseminar uma informação numa rede para os outros computadores que também a compõe. Cada máquina, chamada Peer, possui uma porta com um serviço rodando à escuta de mensagens externas para executar algum tipo de ação. O Gossip implementado pode ser dividido em alguns comportamentos:
 - A cada tempo T1, (segundos) uma *Task* varre um diretório local em busca dos arquivos que lá estão, e monta uma tabela com eles.
 - A cada tempo T2, um peer 𝑿 envia os meta-dados dos seus arquivos para um peer 𝑾. Então, 𝑾 guarda na sua tabela de Peers os estados de 𝑿
 - A cada tempo T3, um peer 𝑾 envia os metadados de 𝑿 para um peer 𝒁, fofocando x.
 - A cada tempo T4, os estados recebidos no tempo *ti*, de tal forma que *ti - t < T4*, são apagados, para todos os peers.


#### Formato da mensagem transferida entre peers via gossip. E tratamento de arquivos duplicados e antigos
As regras que definem o comportamento dos Peers se localizam no arquivo Peer.jl, que utilizam os métodos dentro de Network.jl para se comunicar pela rede. A intenção do projeto é estabelecer uma estrutura hierárquica entre cada arquivo, de tal modo que toda a implementação é estruturada em camadas, como uma cebola. Cada camada só tem acesso às camadas adjacentes. A sequência, do mais alto nível para o mais baixo é:

Peer -> (Gossip + Filesystem) -> (Network + Package + NetUtils)

Desta forma, cada camada "empacota" sua mensagem num *struct* para passar para uma camada mais baixa. A camada do Peer possui um *struct* chamado PeerFS, capaz de guardar a tabela de arquivos e algumas meta-informações de cada peer (nome e porta), e tem o formato:

```julia
mutable struct PeerFS
    name  :: Union{String, Nothing}
    port  :: Union{Int64, Nothing}
    table :: Union{Array{File}, Nothing}
end
```

Em que `table` é a tabela de arquivos do peer, um *Array* de um outro struct chamado *File*, este, que guarda as informações do arquivo em sí.


```julia
mutable struct File
    name   :: String        # Name of the file itself
    mtime  :: Float64       # Unix timestamp of when the file was last modified
    ctime  :: Float64       # Unix timestamp of when the file was created
    mode   :: UInt          # The protection mode of the file
    size   :: Int64         # The size (in bytes) of the file
    collect_time :: Float64 # Unix timestamp of when the file was parsed
    rcv_time     :: Float64 # Unix timestamp of when the file was recieved by peer
end
```

Aqui é importante notar que cada arquivo possui um campo que armazena o momento que ele foi recebido por um peer, `rcv_time`. Assim 𝑿 envia sua tabela com este campo vazio e quando 𝑾 o recebe, preenche com sua hora local. Esta decisão foi tomada pois assim é possível apagar todos os arquivos que não foram recebidos novamente num intervalo de tempo T4, pois assume-se que se o arquivo ainda existe, o receberemos.

Se um peer 𝑿 envia para 𝑾 e 𝒁 seu estado e, a posteriori 𝑾 envia para 𝒁 os estados de 𝑿, então 𝒁 recebeu estados "duplicados" do peer 𝑿. 𝒁 lida com isto da seguinte forma:
 - 𝒁 atualiza todos os campos `rcv_time` dos arquivos recebidos por 𝑾 pela sua hora local.

 - 𝒁 junta a tabela que ele já tem de 𝑿 com o que ele recebeu de 𝑾, e quando existem arquivos com o mesmo nome, é escolhido o que tem o `mtime` maior. Em caso de `mtime` igual, é escolhido o arquivo da última mensagem recebida.

No final, 𝒁 possui uma tabela com os arquivos mais recentes que ele possui do peer 𝑿 com as informações que ele tem a mão. Os arquivos modificados são substituídos e os repetidos têm o mesmo conteúdo, mas com um `rcv_time` mais recente. Assim, arquivos que 𝑿 apagou e passou adiante não será sobrescrevido e começará a ficar datado. Como a cada tempo T4 arquivos que não foram recebidos são apagados, então 𝒁 estará com o estado mais recente de 𝑿.

Portanto, resumindo, arquivos duplicados são usados para reforçar que aquele arquivo ainda existe no peer original, e portanto devemos mantê-los. Quando paramos de receber um determinado arquivo, ele fica antigo e eventualmente é apagado.
