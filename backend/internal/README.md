# Internal backend packages

Private backend packages live here and are not importable by external Go
modules. Shared infrastructure belongs in `platform`; business logic belongs
in its owning service package.
