require 'package'

class Firefox < Package
  description 'Mozilla Firefox (or simply Firefox) is a free and open-source web browser'
  homepage 'https://www.mozilla.org/en-US/firefox/'
  version '93.0'
  license 'MPL-2.0, GPL-2 and LGPL-2.1'
  compatibility 'i686,x86_64'
  case ARCH
  when 'i686'
    source_url "https://download-installer.cdn.mozilla.net/pub/firefox/releases/#{version}/linux-i686/en-US/firefox-#{version}.tar.bz2"
    source_sha256 '56294b9d6b39d94e99a507bb4f1511dbf8a2512a846b8ad49bc93e1253f1e3a8'
  when 'x86_64'
    source_url "https://download-installer.cdn.mozilla.net/pub/firefox/releases/#{version}/linux-x86_64/en-US/firefox-#{version}.tar.bz2"
    source_sha256 '9d06897b80d77cfb59e1c8bd4dfc427590b058616ae634e52cfe272af06f9b32'
  end

  depends_on 'atk'
  depends_on 'cairo'
  depends_on 'dbus'
  depends_on 'dbus_glib'
  depends_on 'fontconfig'
  depends_on 'freetype'
  depends_on 'gdk_pixbuf'
  depends_on 'glib'
  depends_on 'gtk2'
  depends_on 'gtk3'
  depends_on 'libx11'
  depends_on 'libxcb'
  depends_on 'libxcomposite'
  depends_on 'libxcursor'
  depends_on 'libxdamage'
  depends_on 'libxext'
  depends_on 'libxfixes'
  depends_on 'libxi'
  depends_on 'libxrender'
  depends_on 'libxt'
  depends_on 'pango'
  depends_on 'pulseaudio'
  depends_on 'sommelier'

  def self.build
    @firefox_sh = <<~FIREFOX_SH
      #!/bin/bash
      GDK_BACKEND=x11 #{CREW_PREFIX}/firefox/firefox "\$@"
    FIREFOX_SH
    # For some reason, the binaries do not have a desktop file so add it here.
    @firefox_desktop = <<~FIREFOX_DESKTOP
      [Desktop Entry]
      Version=#{version}
      Name=Firefox
      Name[en_US]=firefox
      GenericName=Mozilla Firefox
      GenericName[en_US]=Mozilla Firefox
      Comment=Free and open-source web browser
      Exec=firefox %U
      Terminal=false
      Type=Application
      Icon=firefox
      Categories=Network;WebBrowser;
      MimeType=text/html;text/xml;application/xhtml_xml;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;
    FIREFOX_DESKTOP
  end

  def self.install
    ENV['CREW_FHS_NONCOMPLIANCE_ONLY_ADVISORY'] = '1'
    warn_level = $VERBOSE
    $VERBOSE = nil
    load "#{CREW_LIB_PATH}lib/const.rb"
    $VERBOSE = warn_level
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/bin"
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/firefox"
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/share/applications"
    icon_base_path = "#{CREW_DEST_PREFIX}/share/icons/hicolor"
    FileUtils.mkdir_p "#{icon_base_path}/16x16/apps"
    FileUtils.mkdir_p "#{icon_base_path}/32x32/apps"
    FileUtils.mkdir_p "#{icon_base_path}/48x48/apps"
    FileUtils.mkdir_p "#{icon_base_path}/64x64/apps"
    FileUtils.mkdir_p "#{icon_base_path}/128x128/apps"
    FileUtils.mkdir_p "#{icon_base_path}/256x256/apps"
    FileUtils.cp_r '.', "#{CREW_DEST_PREFIX}/firefox"
    IO.write("#{CREW_DEST_PREFIX}/bin/firefox", @firefox_sh, perm: 0o755)
    IO.write("#{CREW_DEST_PREFIX}/share/applications/firefox.desktop", @firefox_desktop, perm: 0o644)
    Dir.chdir 'browser/chrome/icons/default' do
      FileUtils.mv 'default16.png', "#{icon_base_path}/16x16/apps/firefox.png"
      FileUtils.mv 'default32.png', "#{icon_base_path}/32x32/apps/firefox.png"
      FileUtils.mv 'default48.png', "#{icon_base_path}/48x48/apps/firefox.png"
      FileUtils.mv 'default64.png', "#{icon_base_path}/64x64/apps/firefox.png"
      FileUtils.mv 'default128.png', "#{icon_base_path}/128x128/apps/firefox.png"
    end
    # The following image is needed for crew-launcher which requires a minimum icon size of 144x144.
    system 'curl -L#O https://files.softicons.com/download/application-icons/round-app-icons-by-ampeross/png/256x256/Mozilla.png'
    abort 'Checksum mismatch. :/ Try again.'.lightred unless Digest::SHA256.hexdigest(File.read('Mozilla.png')) == '994e780ada1456c26b077a9f97186aefbc90be5c57e66366b1bca32df0c14c4e'
    FileUtils.mv 'Mozilla.png', "#{icon_base_path}/256x256/apps/firefox.png"
  end

  def self.postinstall
    print "\nSet Firefox as your default browser? [Y/n]: "
    case STDIN.getc
    when "\n", "Y", "y"
      Dir.chdir("#{CREW_PREFIX}/bin") do
        FileUtils.ln_sf 'firefox', 'x-www-browser'
      end
      puts 'Firefox is now your default browser.'.lightgreen
    else
      puts 'No change has been made.'.orange
    end
    puts "\nType 'firefox' to get started.\n".lightblue
  end
end
