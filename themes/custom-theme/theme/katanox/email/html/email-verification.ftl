<#import "template.ftl" as layout>
<@layout.emailLayout>
${kcSanitize(msg("emailVerificationBodyHtml",link+"redirect_uri=${client.baseUrl}/auth/login", linkExpiration, realmName, linkExpirationFormatter(linkExpiration), user.username, user.email))?no_esc}
</@layout.emailLayout>
