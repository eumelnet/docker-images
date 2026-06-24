import smtpd
import asyncore
import subprocess
import logging
import sys

logging.basicConfig(stream=sys.stdout, level=logging.INFO, format='%(asctime)s %(message)s')
log = logging.getLogger('smtp')

class PostfixSMTPServer(smtpd.SMTPServer):
    def process_message(self, peer, mailfrom, rcpttos, data, **kwargs):
        log.info('Mail from %s to %s (%d bytes)', mailfrom, rcpttos, len(data))
        try:
            p = subprocess.run(
                ['/usr/sbin/sendmail', '-f', mailfrom] + list(rcpttos),
                input=data,
                capture_output=True,
                timeout=30
            )
            if p.returncode == 0:
                log.info('Queued to %s', rcpttos)
            else:
                log.error('sendmail exit %d: %s', p.returncode, p.stdout)
        except Exception as e:
            log.error('Error: %s', e)

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 25
    log.info('SMTP frontend on port %d', port)
    server = PostfixSMTPServer(('0.0.0.0', port), None)
    asyncore.loop()
