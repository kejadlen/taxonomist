from sniffer.api import runnable

@runnable
def unittest_discover(*args):
    import unittest
    suite = unittest.defaultTestLoader.discover('.', pattern='*.py')
    result = unittest.TextTestRunner().run(suite)
    return result.wasSuccessful()
