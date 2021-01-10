# Provision AWS CloudFront Web distribution serving content from two S3 buckets

## Variables
* domain (**required**) – the desired domain where to create the Web distribution. Must already have a vaild AWS ACM certificate in the US East (N. Virginia) Region
* allowlist_ip (**default** *[]*) – list of IPv4 CIDR strings for WAF Web ACL to restrict the access. E.G.: ["10.0.0.0/16", "8.0.0.0/8"]

## Output
* app_bucket_arn/app_bucket_name – ARN and name of the S3 bucket with a static Web app
* static_bucket_arn/static_bucket_name – ARN and name of the S3 bucket for static content
* name_servers – list of name servers for the DNS provider

## Usage
* Get a domain. E.G. foo.bar
* Create and verify an AWS ACM certificate for `foo.bar` and `*.foo.bar` in the US East (N. Virginia) Region ([guide](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html)).
* Run `terraform apply` (or `terraform apply -var='allowlist_ip=[\"1.1.1.1/32\"]'` to restrict the access by IP).  
Note, that the access is restricted to IP addresses from **DE** and **NL** anyway.
* Update name servers for the domain to the ones, returned in the `name_servers` output.
* Wait for DNS propagation ([propagation checker](https://www.whatsmydns.net/)).
* Open https://foo.bar. You'll see a default page.
* The app content can be changed in the `<app_bucket_name>` S3 bucket.
* Static content can be added to the `static_bucket_name` S3 bucket.  
Note, that the content **must** be added inside the `static` folder within the bucket.

## TODO
* Add basic authentication
* Implement testing