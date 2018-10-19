import unittest

# set path to modules to be tested
import sys
sys.path.append('../')

# import module for testing
import Config

class TestSession(unittest.TestCase):
 
    def setUp(self):
        session_full = Config.Session(
                              id='test-id' , 
                              name='default' , 
                              prefix='test-' , 
                              path='/tmp/'
                                )

        session_empty = Config.Session(
                              id=None, 
                              name=None,
                              prefix=None , 
                              path=None
                                )
        self.session_full = session_full
        self.session_empty = session_empty
    
    def test_is_class(self):
        self.assertIsInstance(self.session_full, Config.Session , msg='Not of class Session')
        self.assertIsInstance(self.session_empty, Config.Session , msg='Not of class Session')

    def test_create_session(self):
        
        session = Config.Session(
                              id='test-id' , 
                              name='dummy' , 
                              prefix='test-' , 
                              path='/tmp/'
                                )

        self.assertIsInstance(session, Config.Session , msg='Not of class Session')

    def test_access_attributes_filled(self):

        session = self.session_full
        self.assertTrue(session.id, msg="id not set")
        self.assertTrue(session.name, msg="name not set")
        self.assertTrue(session.path, msg="path not set")
        self.assertTrue(session.location, msg="location not set")
        self.assertEqual(session.id , 'test-id')
        self.assertNotEqual(session.name , 'default')
        self.assertEqual(session.name , 'test-default')
             
    def test_access_attributes_empty(self):

        session = self.session_empty
        self.assertTrue(session.id, msg="id not set")
        self.assertTrue(session.name, msg="name not set")
        self.assertFalse(session.path, msg="path not set")
        self.assertTrue(session.location, msg="location not set")

        self.assertRegexpMatches( session.id  , '\d+\-\d+\-\d+\-\d+')
        self.assertNotEqual(session.name , 'default')
        self.assertEqual(session.name , session.id )



class TestDefaults(unittest.TestCase):
    pass

class TestDirectories(unittest.TestCase):
    pass

class TestLocation(unittest.TestCase):
    pass

class TestConfig(unittest.TestCase):
    pass

class TestWorkflow(unittest.TestCase):
    pass

if __name__ == '__main__':
    unittest.main()