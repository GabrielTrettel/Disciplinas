#!/usr/bin/python

from package import Package
import socket, sys, time, threading, random, os

class UDP_Server:
    def __init__(self, port:int = 10923):
        self.PORT = 1243
        self.HEADER_SIZE = 10
        self.skt = self.__init_sckt()
        self.client_queue = []
        self.pkg_handler = Package(55)


    def __init_sckt(self):
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.bind((socket.gethostname(), self.PORT))

        # Escuta um máximo de 5 conexões enfileiradas (Este valor é o valor máximo
        # dependendo do SO) https://docs.python.org/2/library/socket.html#socket.socket.listen
        s.listen(5)
        return s


    def handle_client(self, cli_skt, cli_addr, debug):
        print(f"Conexão com {cli_addr} foi estabelecida.")

        mensagem = "Mensagem de boas vidas do servidor"
        msgs = list(self.pkg_handler.encode_and_split(mensagem, "server"))

        if debug:
            print(*msgs,"",sep="\n")
            aux = msgs[0]       # Fazendo a troca dos elementos para forçar ficar
            msgs[0] = msgs[3]   # fora de ordem. Função random.shuffle() modifica o
            msgs[3] = aux       # conteúdo das strings e por isso não está sendo usado
            print(*msgs,sep="\n")


        for msg in msgs:
            time.sleep(0.5)
            cli_skt.send(msg)

        print(f"    Encerrando conexão com: {cli_addr}")
        cli_skt.close()


    def __close(self, x):
        enter = input("Para sair a qualquer momento, aperte 'q'\n")
        if 'q' in enter:
            self.skt.close()
            os._exit(1)


    def up(self, debug:bool = False):
        x = threading.Thread(target=self.__close, args=(1,))
        x.start()

        while True:
            clientsocket, address = self.skt.accept()

            x = threading.Thread(target=self.handle_client, args=(clientsocket,address,debug,))
            x.start()


if __name__ == '__main__':
    server = UDP_Server()
    server.up(debug=True)
