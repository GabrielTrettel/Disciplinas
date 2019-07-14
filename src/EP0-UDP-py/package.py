#!/usr/bin/python

from typing import Iterator
import pickle, sys, math
import random, copy

class Package:
    """ Uma classe responsável por codificar e decodificar
        mensagens
    """
    encoding = 'utf-8'
    def __init__(self, max_pkg_size:int = 2048, ownership:int = 39, max_pkgs:int = 999):
        # Quantidade de caracteres necessários para guardar o tamanho total do pacote enviado
        # valor default: 2048 -> Valor razoável, mas arbitrário, pode ser "qualquer" inteiro.
        self.MAX_PKG_SIZE = max_pkg_size

        # Quantidade de caracteres necessários para guardar o identificador da ordem do pacote
        # valor default: 999 -> Um numero razoável arbitrário
        self.SEQUENCE_SIZE = len(str(max_pkgs))

        # Quantidade de caracteres necessários para guardar o tamanho dos dados enviados
        # valor default: 4 (quantidade de algarismos mínimo para representar 1024)
        self.DATA_SIZE = len(str(max_pkg_size))

        # Quantidade de caracteres necessários para guardar o identificador do dono do pacote
        # valor default: 39 -> comprimento do IPv6 (Mas pode ser passado qualquer string)
        self.OWNERSHIP_SIZE = ownership

        self.TOTAL_PKGS = self.SEQUENCE_SIZE


        self.HEADER_SIZE = self.DATA_SIZE + self.SEQUENCE_SIZE + self.OWNERSHIP_SIZE + self.TOTAL_PKGS
        self.MAX_DATA_SIZE = self.MAX_PKG_SIZE - self.HEADER_SIZE


    def encode_and_split(self, msg, owner, debug=False) -> Iterator[bytes]:
        """ Codifica e divide a mensagem (quando o tamanho for maior que o máximo)
        Parametros
        ---------
        msg:
        Qualquer objeto do python pode ser passado como mensagem.

        owner:
        Uma string indicando o nome de quem está enviando o pacote

        Retorno
        ---------
        Um generator que devolve a mensagem dividida em multipos pacotes
        quando a codificação ultrapassa o tamanho máximo de caracteres
        """

        owner = f"{owner[:self.OWNERSHIP_SIZE]:<{self.OWNERSHIP_SIZE}}"

        full_msg = pickle.dumps(msg, 0).decode()
        len_full_msg = len(full_msg)
        total = math.ceil(len_full_msg / self.MAX_DATA_SIZE)

        total = f"{total:<{self.TOTAL_PKGS}}"

        i, j = (0, self.MAX_DATA_SIZE)
        seq = 1
        while i < len_full_msg:
            sub_msg  = full_msg[i:j]
            i += self.MAX_DATA_SIZE
            j += self.MAX_DATA_SIZE

            data = f"{len(sub_msg):<{self.DATA_SIZE}}"
            sequence = f"{seq:<{self.SEQUENCE_SIZE}}"
            sub_msg_to_send = data + sequence + total + owner + sub_msg
            seq += 1

            sub_msg_to_send = sub_msg_to_send.encode()
            if debug: print(sub_msg_to_send)

            yield sub_msg_to_send


    def decode_and_merge(self, msgs:list) -> object:
        """ Decodifica todos os pacotes recebidos e reconstrói a mensagem original
        Parametros
        ----------
        msgs :
        Uma lista contendo cada um dos pacotes recebidos, em bytes

        Retorno
        ---------
        Como o conteúdo do pacote pode ser qualquer coisa empacotável com o
        pickle, a especificação do retono é o mais genérica possível, object.
        """

        pkgs_dict = {}

        for pkg in msgs:
            index = self.parse_sequence(pkg)
            msg = Package.decode(pkg)[self.HEADER_SIZE:]
            pkgs_dict[index] = msg


        msg = ""
        for pkg in sorted(pkgs_dict.keys()):
            msg += pkgs_dict[pkg]

        msg = msg.encode()
        return pickle.loads(msg)


    @classmethod
    def decode(cls, msg:bytes) -> str:
        msg = copy.deepcopy(msg)
        return msg.decode()


    def parse_owner(self, msg:bytes) -> str:

        """ Retorna o dono (quem enviou) o pacote

        Parametros
        ----------
        msg: O pacote em si, em bytes

        Retorno
        ----------
        Uma string contendo o valor que estava no header indicado para ser o dono
        """

        i = self.DATA_SIZE + self.SEQUENCE_SIZE + self.TOTAL_PKGS
        j = i + self.OWNERSHIP_SIZE
        return Package.decode(msg)[i:j]


    def parse_sequence(self, msg:bytes) -> str:
        """ Retorna o indice (sequencia) do pacote

        Parametros
        ----------
        msg: O pacote em si, em bytes

        Retorno
        ----------
        Uma string contendo o valor que estava no header indicado para ser a sequencia
        """

        i = self.DATA_SIZE
        j = i + self.SEQUENCE_SIZE
        return Package.decode(msg)[i:j]

    def parse_total(self, msg:bytes) -> str:
        """ Retorna a quantidde total de pacotes indicado pelo header

        Parametros
        ----------
        msg: O pacote em si, em bytes

        Retorno
        ----------
        Uma string contendo o valor que estava no header indicado para ser a
        quantidade total de pacotes
        """

        i = self.DATA_SIZE + self.SEQUENCE_SIZE
        j = i + self.TOTAL_PKGS
        return Package.decode(msg)[i:j]



if __name__ == '__main__':
    pkg_gen = Package(53)
    msg = "----------++++++++++" # Mensagem pode ser qualquer objeto python
    owner = "trettel"

    pkgs = list(pkg_gen.encode_and_split(msg, owner, debug=True))
    random.shuffle(pkgs)
    print('',*pkgs, sep="\n")


    print(f"\nTOTAL PKGS:      {pkg_gen.parse_total(pkgs[2])}")
    print(f"OWNER PKGS:      {pkg_gen.parse_owner(pkgs[2])}")
    print(f"SEQUENCE PKGS 2: {pkg_gen.parse_sequence(pkgs[2])}")

    original_msg = pkg_gen.decode_and_merge(pkgs)
    print(f"Original decoded msg {original_msg}")
