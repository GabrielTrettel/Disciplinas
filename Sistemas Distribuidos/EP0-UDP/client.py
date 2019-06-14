#!/usr/bin/python

import socket
from package import Package
import time, threading, os

class UDP_Client:
    def __init__(self, port:int = 10923, buff:int = 2400):
        self.PORT = port
        self.buff = buff
        self.skt = self.__init_sckt()
        self.pkg_handler = Package(self.buff)

    def __init_sckt(self): # Cria a instância do socket
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect((socket.gethostname(), 1243))
        return s


    def __close(self, x): # Mata o socket quando o usuário aperta q
        enter = input("Para sair a qualquer momento, aperte 'q'\n")
        if 'q' in enter:
            self.skt.close()
            os._exit(1)

    def hear(self):
        """ Escuta e interpreta o que o servidor está mandando para o cliente
        """
        x = threading.Thread(target=self.__close, args=(1,))
        x.start()
        while True:
            full_msg = []
            total_msgs = -1
            new_msg = True

            while True:
                msg = self.skt.recv(self.buff)
                if len(msg) <= 0: continue

                print()

                total_msgs = self.pkg_handler.parse_total(msg)
                curr_msg   = self.pkg_handler.parse_sequence(msg)
                owner      = self.pkg_handler.parse_owner(msg)
                print(f"\33[32m Novo pacote recebido: {curr_msg} do total de {total_msgs} que veio do {owner}")
                print(f"\33[34m    Conteudo do pkg: {msg}")
                print(f"\33[34m    Já foi recebido {len(full_msg)} pacotes")

                full_msg.append(msg)

                if len(full_msg) == int(total_msgs):
                    print("\33[31m Mensagem totalmente recebida:")
                    information = self.pkg_handler.decode_and_merge(full_msg)
                    print(information, "\n\n\33[37m")
                    new_msg = True
                    full_msg = []
                    total_msgs = -1


if __name__ == '__main__':
    client = UDP_Client(buff=55)
    client.hear()
