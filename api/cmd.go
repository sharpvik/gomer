package main

import (
	"context"
	"io"
	"log"
	"os/exec"
)

type Cmd struct {
	*exec.Cmd
}

func Command(dir, name string, args ...string) *Cmd {
	cmd := exec.Command(name, args...)
	cmd.Dir = dir
	return &Cmd{Cmd: cmd}
}

func CommandContext(ctx context.Context, dir, name string, args ...string) *Cmd {
	cmd := exec.CommandContext(ctx, name, args...)
	cmd.Dir = dir
	return &Cmd{Cmd: cmd}
}

func (cmd *Cmd) Pipe(w io.Writer) *Cmd {
	cmd.Stdout = w
	cmd.Stderr = w
	return cmd
}

func (cmd *Cmd) Run() error {
	if err := cmd.Cmd.Run(); err != nil {
		log.Printf("error running '%s': %v", cmd.String(), err)
		return err
	}

	return nil
}
