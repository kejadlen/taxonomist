from sniffer.api import runnable

@runnable
def unittest_discover(*args):
    import unittest
    suite = unittest.defaultTestLoader.discover('.', pattern='*.py')
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    return result.wasSuccessful()
