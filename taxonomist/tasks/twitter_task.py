from Queue import Queue
from threading import Thread


class TwitterTask(object):
    def __init__(self, twitter):
        self.twitter = twitter

        self.queue = Queue()
        self.thread = Thread(target=self.run)
        self.thread.daemon = True
        self.thread.start()

    def run(self):
        while True:
            user = self.get()
            self.process(user)
            self.queue.task_done()

    def process(self, user):
        pass

    def get(self):
        return self.queue.get()

    def put(self, user):
        self.queue.put(user)

    def join(self):
        self.queue.join()
