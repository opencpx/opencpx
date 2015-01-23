#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "config.h"  /* Perl's config.h tells us lots about this box */
#ifdef D_USE_SYS_TIME
#include <sys/time.h>
#else
#include <time.h>    /* for time_t struct */
#endif /* D_USE_SYS_TIME */

MODULE = VSAP::Server::G11N::Date		PACKAGE = VSAP::Server::G11N::Date		

SV *
localtime(when)
        time_t when
        PROTOTYPE: $
        CODE:
        time_t mytime    = when;
        struct tm *tmbuf;
        tzset();
	tmbuf = localtime(&mytime);

        if( GIMME_V == G_ARRAY) {
                POPs;
                XPUSHs(sv_2mortal(newSViv(tmbuf->tm_sec)));
                XPUSHs(sv_2mortal(newSViv(tmbuf->tm_min)));
                XPUSHs(sv_2mortal(newSViv(tmbuf->tm_hour)));
                XPUSHs(sv_2mortal(newSViv(tmbuf->tm_mday)));
                XPUSHs(sv_2mortal(newSViv(tmbuf->tm_mon+1)));
                XPUSHs(sv_2mortal(newSViv(tmbuf->tm_year+1900)));
                XPUSHs(sv_2mortal(newSViv(tmbuf->tm_wday)));
                XPUSHs(sv_2mortal(newSViv(tmbuf->tm_yday)));
                XPUSHs(sv_2mortal(newSViv(tmbuf->tm_isdst)));
#ifdef D_HAS_TM_ZONE
                XPUSHs(sv_2mortal(newSVpv(tmbuf->tm_zone, 0)));
#else
#  ifdef D_HAS_TZNAME
		XPUSHs(sv_2mortal(newSVpv( (tmbuf->tm_isdst ? tzname[1] : tzname[0]), 0)));
#  else
		XPUSHs(sv_2mortal(newSVpv(getenv("TZ"), 0)));
#  endif /* D_HAS_TZNAME */
#endif /* D_HAS_TM_ZONE */
#ifdef D_HAS_TM_GMTOFF
                XPUSHs(sv_2mortal(newSViv(tmbuf->tm_gmtoff)));
#else
#  ifdef D_HAS_TIMEZONE /* SysV seconds from UTC */
		XPUSHs(sv_2mortal(newSViv( (tmbuf->tm_isdst && daylight ? -altzone : -timezone) )));
#  else
		XPUSHs(sv_2mortal(newSViv(0)));
#  endif /* defined D_HAS_TIMEZONE */
#endif /* defined D_TM_GMTOFF */

                XSRETURN(13);
        }
        else {
                sv_setsv(ST(0), &PL_sv_undef);
        }
