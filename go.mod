module github.com/imjoshholloway/protorepo

go 1.14

// We need to refer to grpc-gateway here otherwise other repos break because they
// can't resolve the dependencies.
require github.com/grpc-ecosystem/grpc-gateway v1.14.6
