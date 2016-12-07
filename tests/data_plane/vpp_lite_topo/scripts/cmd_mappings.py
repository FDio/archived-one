
mappings = {}

class SimpleMapping(object):

  def __init__(self, cmd, cli, vat):
    if cmd in mappings:
      raise Exception('{} already in cmd db!'.format(cmd))

    self.cmd = cmd
    self.cli = cli
    self.vat = vat
    mappings[cmd] = self

  def generate(self, mode, args):
    s = ''
    # simply append arguments string to right command
    if mode == 'vat':
      s = self.vat + ' ' + args
    else:
      s = self.cli + ' ' + args
    return s


class CustomMapping(SimpleMapping):

  def generate(self, mode, args):
    s = ''
    if mode == 'vat':
      s = self.vat
    else:
      s = self.cli

    args = args.split(' ')
    return s.format(*args)


class RepeatableLocators(SimpleMapping):

  def generate(self, mode, args):
    name = args[:args.index(' ')]  # first word is ls name
    locs = args[args.index(' '):]

    if mode == 'vat':
      s = self.vat
    else:
      s = self.cli

    s = s + ' ' + name + locs
    return s


SimpleMapping('lisp_state', 'lisp', 'lisp_enable_disable')
SimpleMapping('lisp_map_resolver', 'lisp map-resolver', 'lisp_add_del_map_resolver')
SimpleMapping('lisp_map_server', 'lisp map-server', 'lisp_add_del_map_server')
SimpleMapping('lisp_local_eid', 'lisp eid-table', 'lisp_add_del_local_eid')
SimpleMapping('lisp_remote_mapping', 'lisp remote-mapping', 'lisp_add_del_remote_mapping')
SimpleMapping('lisp_pitr', 'lisp pitr ls', 'lisp_pitr_set_locator_set locator-set')
SimpleMapping('lisp_adjacency', 'lisp adjacency', 'lisp_add_del_adjacency')
SimpleMapping('lisp_map_request_mode', 'lisp map-request mode', 'lisp_map_request_mode')
SimpleMapping('set_if_ip', 'set int ip address', 'sw_interface_add_del_address')
SimpleMapping('lisp_rloc_probe_state', 'lisp rloc-probe', 'lisp_rloc_probe_enable_disable')
SimpleMapping('lisp_map_register_state', 'lisp map-register', 'lisp_map_register_enable_disable')

CustomMapping('lisp_eid_map_bd',
              'lisp eid-table map vni {0} bd {1}',
              'lisp_eid_table_add_del_map vni {0} bd_index {1}')
CustomMapping('lisp_eid_map_vrf',
              'lisp eid-table map vni {0} vrf {1}',
              'lisp_eid_table_add_del_map vni {0} vrf {1}')
CustomMapping('set_if_l2_bridge', 'set interface l2 bridge {0} {1}',
              'sw_interface_set_l2_bridge {0} bd_id {1}')
CustomMapping('set_if_ip_table', 'set interface ip table {0} {1}',
              'sw_interface_set_table {0} vrf {1}')
CustomMapping('lisp_locator_set_with_locator',
              'lisp locator-set add {0} iface {1} p {2} w {3}',
              'lisp_add_del_locator_set locator-set {0} iface {1} p {2} w {3}')
CustomMapping('create_host_iface',
    'create host-interface name {0}\n'
    'set int state host-{0} up\n'
    'set int ip address host-{0} {1}',

    'af_packet_create name {0}\n'
    'sw_interface_set_flags host-{0} admin-up link-up\n'
    'sw_interface_add_del_address host-{0} {1}')

CustomMapping('create_host_iface_vrf',
    'create host-interface name {0}\n'
    'set int state host-{0} up\n'
    'set interface ip table host-{0} {2}\n'
    'set int ip address host-{0} {1}',

    'af_packet_create name {0}\n'
    'sw_interface_set_flags host-{0} admin-up link-up\n'
    'sw_interface_set_table host-{0} vrf {2}\n'
    'sw_interface_add_del_address host-{0} {1}')

CustomMapping('create_host_iface_vrf_v6',
    'create host-interface name {0}\n'
    'set int state host-{0} up\n'
    'set interface ip6 table host-{0} {2}\n'
    'set int ip address host-{0} {1}',

    'af_packet_create name {0}\n'
    'sw_interface_set_flags host-{0} admin-up link-up\n'
    'sw_interface_set_table host-{0} vrf {2} ipv6\n'
    'sw_interface_add_del_address host-{0} {1}')

RepeatableLocators('lisp_ls_multiple_locs',
                   'lisp locator-set add',
                   'lisp_add_del_locator_set locator-set')

