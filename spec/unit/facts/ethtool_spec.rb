require 'spec_helper'
require 'facter/ethtool'

describe Ethtool::Facts do

  describe '#exists?' do
    it 'returns true if ethtool is installed' do
      File.stubs(:exists?).returns(true)
      expect(Ethtool::Facts.exists?).to eq(true)
    end
    
    it 'returns false if ethtool is not installed' do
      File.stubs(:exists?).returns(false)
      expect(Ethtool::Facts.exists?).to eq(false)
    end
  end

  describe '#interfaces' do
    it 'returns an array of interfaces without parent directories or virtual interfaces' do
      Dir.stubs(:foreach).returns(['.', '..', 'eth0', 'lo', 'veth0'])
      expect(Ethtool::Facts.interfaces).to eq(['eth0', 'lo'])
    end
  end

  describe '#alphafy' do
    it 'replaces non alphanumeric characters' do
      expect(Ethtool::Facts.alphafy('eth0.10')).to eq('eth0_10')
    end
  end

  describe '#speeds' do
    it 'returns a hash of speeds for interfaces' do
      Ethtool::Facts.stubs(:interfaces).returns(['vboxnet0'])
      Ethtool::Facts.stubs(:ethtool).returns('Settings for vboxnet0:
  Supported ports: [ ]
  Supported link modes:   Not reported
  Supported pause frame use: No
  Supports auto-negotiation: No
  Advertised link modes:  Not reported
  Advertised pause frame use: No
  Advertised auto-negotiation: No
  Speed: 10Mb/s
  Duplex: Full
  Port: Twisted Pair
  PHYAD: 0
  Transceiver: internal
  Auto-negotiation: off
  MDI-X: Unknown
  Link detected: no')
      expect(Ethtool::Facts.speeds).to eq({'vboxnet0' => '10'})
    end
  end

  describe '#max_speeds' do
    it 'returns a hash of maximum speeds for interfaces' do
      Ethtool::Facts.stubs(:interfaces).returns(['enp0s25'])
      Ethtool::Facts.stubs(:ethtool).returns('Settings for enp0s25:
  Supported ports: [ TP ]
  Supported link modes:   10baseT/Half 10baseT/Full 
                          100baseT/Half 100baseT/Full 
                          1000baseT/Full 
  Supported pause frame use: No
  Supports auto-negotiation: Yes
  Advertised link modes:  10baseT/Half 10baseT/Full 
                          100baseT/Half 100baseT/Full 
                          1000baseT/Full 
  Advertised pause frame use: No
  Advertised auto-negotiation: Yes
  Speed: Unknown!
  Duplex: Unknown! (255)
  Port: Twisted Pair
  PHYAD: 2
  Transceiver: internal
  Auto-negotiation: on
  MDI-X: Unknown (auto)
  Current message level: 0x00000007 (7)
             drv probe link
  Link detected: no')
      expect(Ethtool::Facts.max_speeds).to eq({'enp0s25' => '1000'})
    end
  end

  context "On linux when ethtool works" do
    before do
      Facter.clear
      Facter.fact(:kernel).stubs(:value).returns("Linux")
      Ethtool::Facts.stubs(:exists?).returns(true)
      Ethtool::Facts.stubs(:interfaces).returns(['testeth'])
      Ethtool::Facts.stubs(:ethtool).returns('  Speed: 42Mb/s')
      Ethtool::Facts.facts
    end
    it "Should report back just the number in Mb/s" do
      expect(Facter.fact(:speed_testeth).value).to eq('42')
    end
  end

  context "On linux when ethtool doesn't work" do
    before do
      Facter.clear
      Facter.fact(:kernel).stubs(:value).returns("Linux")
      Ethtool::Facts.stubs(:exists?).returns(true)
      Ethtool::Facts.stubs(:interfaces).returns(['testeth'])
      Ethtool::Facts.stubs(:ethtool).returns('')
      Ethtool::Facts.facts
    end
    it "The fact shouldn't be there" do
      expect(Facter.fact(:speed_testeth)).to be_nil
    end
  end

  context "On an unsupported OS" do
    before do
      Facter.fact(:kernel).stubs(:value).returns('windows')
      Facter.fact(:kernelrelease).stubs(:value).returns('6.1.7601')
      Ethtool::Facts.stubs(:exists?).returns(true)
      Ethtool::Facts.stubs(:interfaces).returns(['WINDOWS_INTERFACE'])
      Ethtool::Facts.facts
    end
    it "Should not have a fact" do
      expect(Facter.fact(:speed_WINDOWS_INTERFACE)).to be_nil
    end
  end

  after :each do
    # Make sure we're clearing out Facter every time
    Facter.clear
    Facter.clear_messages
  end

end
