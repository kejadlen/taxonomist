import logging

logger = logging.getLogger('taxonomist')
logger.setLevel(logging.WARNING)

ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)

fmt = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
formatter = logging.Formatter(fmt)
ch.setFormatter(formatter)

logger.addHandler(ch)
