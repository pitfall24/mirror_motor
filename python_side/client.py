from sipyco.pc_rpc import Client as SiPyCoClient

# class to handle accessing attributes on a MirrorMotor instance remotely
# remote since this is called from a client remotely connecting to the server
class RemoteAttributeProxy:
    def __init__(self, client, base_path=''):
        self._client = client
        self._base_path = base_path
    
    def __getattr__(self, name):
        return RemoteAttributeProxy(self._client, base_path=f'{self._base_path}.{name}'.strip('.'))
    
    def __call__(self, *args, **kwargs):
        parts = self._base_path.rsplit('.', 1)

        if len(parts) == 2:
            path, method = parts
        else:
            path, method = '', parts[0]
        
        return self._client.call_method(path, method, *args, **kwargs)
    
    def reboot(self):
        self._client.reboot()

# interface so the user doesnt have to wrap sipyco.pr_rpc.Client on their own
class Client:
    '''
    Equivalent to writing:
    `mirror_motor = RemoteAttributeProxy(SiPyCoClient(host, port))`
    
    but is more convenient for the user.
    '''
    def __init__(self, host, port, target=None):
        if target is None:
            self.client = RemoteAttributeProxy(SiPyCoClient(host, port))
        else:
            self.client = RemoteAttributeProxy(SiPyCoClient(host, port, target=target))
    
    def __getattr__(self, name):
        return self.client.__getattr__(name)
    
    def __call__(self, method, *args, **kwargs):
        return self.client(*args, *kwargs)
    
    def reboot(self):
        self.client.reboot()

