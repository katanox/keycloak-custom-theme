<#import "template.ftl" as layout>
<@layout.emailLayout>
${kcSanitize(msg("emailVerificationBodyHtml",link, linkExpiration, realmName, linkExpirationFormatter(linkExpiration), user.firstName, user.email))?no_esc}
</@layout.emailLayout>
