class Shock(Report):
    """docstring for ClassName"""

    def __init__(self, arg):
        super(ClassName, self).__init__()
        self.arg = arg

        self.name = None
        self.date = None
        self.host = None
        self.summary = {}
        self.tests = [

            {
                "name": none,
                "status": None,
                "steps": {
                    "setup": {
                        "status": None,
                        "run": {
                            "total": None,
                            "success": None,
                            "failed": None,
                        }
                    }
                    "message": None,
                    "ref": {"URI": None}
                },
                "build": {
                    "status": None,
                    "run": {
                        "total": None,
                        "success": None,
                        "failed": None
                    }
                    "message": None,
                    "ref": {"URI": None}
                },
                "run": {
                    "status": None,
                    "run": {
                        "total": None,
                        "success": None,
                        "failed": None,
                    },
                    "message": None,
                    "ref": {"URI": None}
                },
                "postproc": {
                    "status": None,
                    "run": {
                        "total": None,
                        "success": None,
                        "failed": None,
                    }
                    "message": None,
                    "ref": {"URI": None}
                }

            }
        ]
